/*
TEST: public.verify_subscription RPC function

Verifies the verify_subscription function exists and works correctly per
migration 20260225100001_create_rpc_verify_subscription.sql.

Setup: Requires pgtap extension in extensions schema. Creates test subscriptions.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

select plan(9)
;

-- Setup
create table if not exists test_data.test_newsletter_verify (label text primary key, token uuid not null, email text not null);
truncate table test_data.test_newsletter_verify;
grant all
on schema test_data
to postgres, anon, authenticated
;
grant all
on table test_data.test_newsletter_verify
to postgres, anon, authenticated
;

-- Create pending subscription for testing
with
    ins as (
        insert into public.newsletter_subscriptions(email, verified)
        values ('verify-test@example.com', false)
        returning token, email
    )
    insert into test_data.test_newsletter_verify(label, token, email)
select 'pending', token, email
from ins
;

-- Create already verified subscription
with
    ins as (
        insert into public.newsletter_subscriptions(
            email, verified, verified_at, consumed_at
        )
        values ('already-verified@example.com', true, now(), now())
        returning token, email
    )
    insert into test_data.test_newsletter_verify(label, token, email)
select 'verified', token, email
from ins
;

-- Create pending subscription for email mismatch test
with
    ins as (
        insert into public.newsletter_subscriptions(email, verified)
        values ('mismatch-test@example.com', false)
        returning token, email
    )
    insert into test_data.test_newsletter_verify(label, token, email)
select 'mismatch', token, email
from ins
;

-- Store tokens for testing
select
    set_config(
        'test.pending_token',
        (
            select token from test_data.test_newsletter_verify where label = 'pending'
        )::text,
        false
    )
;

select
    set_config(
        'test.verified_token',
        (
            select token from test_data.test_newsletter_verify where label = 'verified'
        )::text,
        false
    )
;

select
    set_config(
        'test.mismatch_token',
        (
            select token from test_data.test_newsletter_verify where label = 'mismatch'
        )::text,
        false
    )
;

-- function exists
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'verify_subscription'
        ),
        'Function public.verify_subscription exists'
    )
;

-- function signature
select
    ok(
        (
            select pg_get_function_arguments(p.oid) = 'p_token uuid, p_email text'
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'verify_subscription'
        ),
        'Function signature is (uuid, text)'
    )
;

-- anon can execute verify_subscription
set local role anon
;

select
    lives_ok(
        format(
            $$select public.verify_subscription('%s', 'verify-test@example.com')$$,
            current_setting('test.pending_token', true)
        ),
        'anon can execute verify_subscription'
    )
;

-- after verification,
-- subscription is verified
set local role service_role
;

select
    ok(
        (
            select verified
            from public.newsletter_subscriptions
            where email = 'verify-test@example.com'
        )
        = true,
        'subscription is verified after verify_subscription'
    )
;

-- verified_at and consumed_at are set
select
    ok(
        (
            select verified_at is not null
            from public.newsletter_subscriptions
            where email = 'verify-test@example.com'
        )
        and (
            select consumed_at is not null
            from public.newsletter_subscriptions
            where email = 'verify-test@example.com'
        ),
        'verified_at and consumed_at are set'
    )
;

-- cannot verify again (already verified)
set local role anon
;

select
    throws_like(
        format(
            $$select public.verify_subscription('%s', 'verify-test@example.com')$$,
            current_setting('test.pending_token', true)
        ),
        '%Already verified%',
        'cannot verify already verified subscription'
    )
;

-- invalid token throws error
select
    throws_like(
        $$select public.verify_subscription('00000000-0000-0000-0000-000000000000'::uuid, 'test@example.com')$$,
        '%Invalid token%',
        'invalid token throws error'
    )
;

-- email mismatch throws error
set local role anon
;

select
    throws_like(
        format(
            $$select public.verify_subscription('%s', 'wrong-email@example.com')$$,
            current_setting('test.mismatch_token', true)
        ),
        '%Email mismatch%',
        'email mismatch throws error'
    )
;

-- function returns boolean
select
    ok(
        (
            select pg_get_function_result(p.oid) = 'boolean'
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'verify_subscription'
        ),
        'Function returns boolean'
    )
;

select *
from finish()
;

rollback
;

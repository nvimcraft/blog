/*
TEST: public.unsubscribe RPC function

Verifies the unsubscribe function exists and works correctly per
migration 20260225100002_create_rpc_unsubscribe.sql.

Setup: Requires pgtap extension in extensions schema. Creates test subscriptions.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

select plan(8)
;

-- Setup
create table if not exists test_data.test_newsletter_unsubscribe (label text primary key, token uuid not null, email text not null);
truncate table test_data.test_newsletter_unsubscribe;
grant all
on schema test_data
to postgres, anon, authenticated
;
grant all
on table test_data.test_newsletter_unsubscribe
to postgres, anon, authenticated
;

-- Create verified subscription for unsubscribe testing
with
    ins as (
        insert into public.newsletter_subscriptions(
            email, verified, verified_at, consumed_at
        )
        values ('unsubscribe-test@example.com', true, now(), now())
        returning token, email
    )
    insert into test_data.test_newsletter_unsubscribe(label, token, email)
select 'verified', token, email
from ins
;

-- Create already unsubscribed subscription
with
    ins as (
        insert into public.newsletter_subscriptions(
            email, verified, verified_at, consumed_at, unsubscribed_at
        )
        values ('already-unsubscribed@example.com', false, now(), now(), now())
        returning token, email
    )
    insert into test_data.test_newsletter_unsubscribe(label, token, email)
select 'unsubscribed', token, email
from ins
;

-- Store tokens for testing
select
    set_config(
        'test.unsubscribe_token',
        (
            select token
            from test_data.test_newsletter_unsubscribe
            where label = 'verified'
        )::text,
        false
    )
;

select
    set_config(
        'test.already_unsubscribed_token',
        (
            select token
            from test_data.test_newsletter_unsubscribe
            where label = 'unsubscribed'
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
            where n.nspname = 'public' and p.proname = 'unsubscribe'
        ),
        'Function public.unsubscribe exists'
    )
;

-- function signature
select
    ok(
        (
            select pg_get_function_arguments(p.oid) = 'p_token uuid'
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'unsubscribe'
        ),
        'Function signature is (uuid)'
    )
;

-- anon can execute unsubscribe
set local role anon
;

select
    lives_ok(
        format(
            $$select public.unsubscribe('%s')$$,
            current_setting('test.unsubscribe_token', true)
        ),
        'anon can execute unsubscribe'
    )
;

-- after unsubscribe,
-- verified is false
set local role service_role
;

select
    ok(
        (
            select verified
            from public.newsletter_subscriptions
            where email = 'unsubscribe-test@example.com'
        )
        = false,
        'subscription is not verified after unsubscribe'
    )
;

-- unsubscribed_at is set
select
    ok(
        (
            select unsubscribed_at is not null
            from public.newsletter_subscriptions
            where email = 'unsubscribe-test@example.com'
        ),
        'unsubscribed_at is set'
    )
;

-- cannot unsubscribe again (already unsubscribed)
set local role anon
;

select
    throws_like(
        format(
            $$select public.unsubscribe('%s')$$,
            current_setting('test.unsubscribe_token', true)
        ),
        '%Already unsubscribed%',
        'cannot unsubscribe already unsubscribed subscription'
    )
;

-- invalid token throws error
select
    throws_like(
        $$select public.unsubscribe('00000000-0000-0000-0000-000000000000'::uuid)$$,
        '%Invalid token%',
        'invalid token throws error'
    )
;

-- function returns boolean
select
    ok(
        (
            select pg_get_function_result(p.oid) = 'boolean'
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'unsubscribe'
        ),
        'Function returns boolean'
    )
;

select *
from finish()
;

rollback
;

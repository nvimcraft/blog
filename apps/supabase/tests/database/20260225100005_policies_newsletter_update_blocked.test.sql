/*
TEST: Newsletter UPDATE policy (blocked)

Verifies UPDATE policy on newsletter_subscriptions matches
migration 20260225100005_policies_newsletter_update_blocked.sql.

Setup: Requires pgtap extension in extensions schema. Creates test subscription.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

select plan(2)
;

-- Setup
create table if not exists test_data.test_newsletter_ids (label text primary key, id uuid not null);
truncate table test_data.test_newsletter_ids;
grant all
on schema test_data
to postgres, anon, authenticated
;
grant all
on table test_data.test_newsletter_ids
to postgres, anon, authenticated
;

-- Create test subscription
with
    ins as (
        insert into public.newsletter_subscriptions(email, verified)
        values ('policies-newsletter-test@example.com', false)
        returning id, token
    )
    insert into test_data.test_newsletter_ids(label, id)
select 'pending', id
from ins
;

-- UPDATE policy is blocked for anon, authenticated
select
    policy_cmd_is(
        'public',
        'newsletter_subscriptions',
        'newsletter_subscriptions_update_blocked',
        'UPDATE',
        'update policy command is UPDATE'
    )
;

-- UPDATE behavior: anon cannot update (RLS silently filters)
set local role anon
;

select
    is_empty(
        $$update public.newsletter_subscriptions set verified = true where email = 'policies-newsletter-test@example.com' returning id$$,
        'anon cannot update subscriptions'
    )
;

select *
from finish()
;

rollback
;

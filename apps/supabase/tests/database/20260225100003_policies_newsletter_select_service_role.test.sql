/*
TEST: Newsletter SELECT policy (service_role only)

Verifies SELECT policy on newsletter_subscriptions matches
migration 20260225100003_policies_newsletter_select_service_role.sql.

Setup: Requires pgtap extension in extensions schema. Creates test subscription.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

select plan(3)
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

-- select policy is for service_role only
select
    policy_roles_are(
        'public',
        'newsletter_subscriptions',
        'newsletter_subscriptions_select_service_role',
        array['service_role'],
        'select policy applies only to service_role'
    )
;

-- select behavior: anon cannot read (email privacy)
set local role anon
;

select
    is_empty(
        $$select id from public.newsletter_subscriptions$$,
        'anon cannot select any subscriptions'
    )
;

-- service_role can select all
set local role service_role
;

select
    results_eq(
        $$select count(*) from public.newsletter_subscriptions$$,
        array[1::bigint],
        'service_role can select all subscriptions'
    )
;

select *
from finish()
;

rollback
;

/*
TEST: Newsletter DELETE policy (service_role only)

Verifies DELETE policy on newsletter_subscriptions matches
migration 20260225100006_policies_newsletter_delete_service_role.sql.

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

-- DELETE policy is for service_role only
select
    policy_roles_are(
        'public',
        'newsletter_subscriptions',
        'newsletter_subscriptions_delete_service_role',
        array['service_role'],
        'delete policy applies only to service_role'
    )
;

-- DELETE behavior: anon cannot delete (RLS silently filters)
set local role anon
;

select
    is_empty(
        $$delete from public.newsletter_subscriptions where email = 'policies-newsletter-test@example.com' returning id$$,
        'anon cannot delete subscriptions'
    )
;

-- service_role can DELETE
set local role service_role
;

select
    isnt_empty(
        $$delete from public.newsletter_subscriptions where email = 'policies-newsletter-test@example.com' returning id$$,
        'service_role can delete subscriptions'
    )
;

select *
from finish()
;

rollback
;

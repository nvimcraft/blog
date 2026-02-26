/*
TEST: RLS policies on public.profiles

Verifies RLS policies on profiles table match migration 20260222101635_policies_profiles.sql.

Setup: Requires pgtap extension in extensions schema. Creates test users.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

select plan(13)
;

-- Setup: create 2 users (profiles created by your auth trigger)
-- Use valid usernames that satisfy profiles_username_check.
-- Also use unique emails to avoid collisions across reruns.
insert into auth.users (id, email, raw_user_meta_data, created_at)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'policy-profiles-a1@example.com', '{"username":"policy-user-one"}'::jsonb, now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'policy-profiles-b2@example.com', '{"username":"policy-user-two"}'::jsonb, now());

-- RLS enabled on public.profiles
select
    ok(
        exists (
            select 1
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where
                n.nspname = 'public'
                and c.relname = 'profiles'
                and c.relrowsecurity is true
        ),
        'RLS is enabled on public.profiles'
    )
;

-- Policy set is exactly expected
select
    policies_are(
        'public',
        'profiles',
        array['profiles_select_public', 'profiles_insert_own', 'profiles_update_own']
    )
;

-- Policy scoping checks (roles)
select
    policy_roles_are(
        'public',
        'profiles',
        'profiles_select_public',
        array['anon', 'authenticated'],
        'select policy applies to anon + authenticated'
    )
;

select
    policy_roles_are(
        'public',
        'profiles',
        'profiles_insert_own',
        array['authenticated'],
        'insert policy applies only to authenticated'
    )
;

select
    policy_roles_are(
        'public',
        'profiles',
        'profiles_update_own',
        array['authenticated'],
        'update policy applies only to authenticated'
    )
;

-- Policy command checks
select
    policy_cmd_is(
        'public',
        'profiles',
        'profiles_insert_own',
        'INSERT',
        'insert policy command is INSERT'
    )
;

select
    policy_cmd_is(
        'public',
        'profiles',
        'profiles_update_own',
        'UPDATE',
        'update policy command is UPDATE'
    )
;

-- Behavior
-- As anon: can read profiles (policy USING true)
-- Make this deterministic: count only the two profiles created above.
set local role anon
;

select results_eq($$
  select count(*)
  from public.profiles
  where id in (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1'::uuid,
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2'::uuid
  )
  $$, array[2::bigint], 'anon can read profiles for attribution (test users only)')
;

-- As anon: cannot insert (FK passes but RLS blocks)
select throws_like($$
  insert into public.profiles (id, username)
  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'nope');
  $$, '%row-level security%', 'anon cannot insert profiles')
;

-- Reset role before creating more test users
reset role
;

-- As authenticated user3: can insert own profile (non-trigger flow)
-- Create auth user3 (trigger creates profile), delete it, then insert it back as user3.
insert into auth.users (id, email, raw_user_meta_data, created_at)
values
  ('cccccccc-cccc-cccc-cccc-ccccccccccc3', 'policy-profiles-c3@example.com', '{"username":"policy-user-three"}'::jsonb, now());

delete from public.profiles
where id = 'cccccccc-cccc-cccc-cccc-ccccccccccc3'::uuid
;

set local role authenticated
;
set local request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-ccccccccccc3'
;

select lives_ok($$
  insert into public.profiles (id, username)
  values ('cccccccc-cccc-cccc-cccc-ccccccccccc3'::uuid, 'policy-user-three');
  $$, 'authenticated user can insert own profile row')
;

select
    throws_like(
        $$
  insert into public.profiles (id, username)
  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'spoof-user');
  $$,
        '%row-level security%',
        'authenticated user cannot insert profile for another user'
    )
;

-- Authenticated: can update own profile
select isnt_empty($$
  update public.profiles
  set username = 'policy-user-three-updated'
  where id = 'cccccccc-cccc-cccc-cccc-ccccccccccc3'::uuid
  returning id
  $$, 'authenticated user can update own profile')
;

-- authenticated cannot update someone else’s profile (0 rows)
select is_empty($$
  update public.profiles
  set username = 'hacked-user'
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1'::uuid
  returning id
  $$, 'authenticated user cannot update another user profile')
;

select *
from finish()
;
rollback
;

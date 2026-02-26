/*
TEST: public.handle_new_user trigger function

Verifies the handle_new_user trigger function and on_auth_user_created trigger
are correctly configured to create profiles on user signup.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

create extension if not exists pgtap with schema extensions;

select plan(9)
;

-- Constants used in this test (avoid collisions across reruns)
-- Use unique IDs + emails that are unlikely to exist already.
-- Username must satisfy your profiles_username_check (4-30 chars, regex).
-- Use unique username to avoid conflicts with seeded data.
-- user_ok: has username
-- user_missing: missing username
-- Function exists (public.handle_new_user)
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'handle_new_user'
        ),
        'public.handle_new_user() exists'
    )
;

-- Function returns trigger
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            join pg_type t on t.oid = p.prorettype
            where
                n.nspname = 'public'
                and p.proname = 'handle_new_user'
                and t.typname = 'trigger'
        ),
        'public.handle_new_user() returns trigger'
    )
;

-- Function is SECURITY DEFINER (permissions safety)
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where
                n.nspname = 'public'
                and p.proname = 'handle_new_user'
                and p.prosecdef is true
        ),
        'public.handle_new_user() is SECURITY DEFINER'
    )
;

-- Function sets search_path to empty (robust check)
-- proconfig stores settings like search_path; normalize to allow search_path= or
-- search_path="".
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            cross join lateral unnest(p.proconfig) cfg
            where
                n.nspname = 'public'
                and p.proname = 'handle_new_user'
                and cfg like 'search_path=%'
                and length(btrim(regexp_replace(cfg, '^search_path=', ''), '"''')) = 0
        ),
        'public.handle_new_user() sets search_path to empty'
    )
;

-- Trigger exists on auth.users and is AFTER INSERT FOR EACH ROW calling
-- public.handle_new_user()
-- Use pg_trigger (more reliable than information_schema for protected schemas like
-- auth).
select
    ok(
        exists (
            select 1
            from pg_trigger tg
            join pg_class c on c.oid = tg.tgrelid
            join pg_namespace ns on ns.oid = c.relnamespace
            join pg_proc f on f.oid = tg.tgfoid
            join pg_namespace fns on fns.oid = f.pronamespace
            where
                ns.nspname = 'auth'
                and c.relname = 'users'
                and tg.tgname = 'on_auth_user_created'
                and fns.nspname = 'public'
                and f.proname = 'handle_new_user'
                and (tg.tgtype & 1) = 1  -- FOR EACH ROW
                and (tg.tgtype & 4) = 4  -- INSERT
                and (tg.tgtype & 2) = 0  -- NOT BEFORE => AFTER
                and tg.tgenabled <> 'D'
        ),
        'trigger on_auth_user_created exists on auth.users AFTER INSERT and calls public.handle_new_user()'
    )
;

-- Behavior: inserting auth.users with username should succeed (unique email!)
select lives_ok($$
  insert into auth.users (id, email, raw_user_meta_data, created_at)
  values (
    '00000000-0000-0000-0000-000000000201',
    'trigger-test-000000000201@example.com',
    '{"username":"test-user-201"}'::jsonb,
    now()
  );
  $$, 'auth.users insert with username succeeds')
;

-- Profile row created with same id
select
    ok(
        exists (
            select 1
            from public.profiles
            where id = '00000000-0000-0000-0000-000000000201'
        ),
        'profiles row is created for new auth user'
    )
;

-- Username stored exactly as provided (no lowercasing in this function)
select
    is (
        (
            select username::text
            from public.profiles
            where id = '00000000-0000-0000-0000-000000000201'
        ),
        'test-user-201',
        'profiles.username stored as provided by raw_user_meta_data'
    )
;

-- Missing username fails fast with expected exception message (unique email + id)
select throws_ok($$
  insert into auth.users (id, email, raw_user_meta_data, created_at)
  values (
    '00000000-0000-0000-0000-000000000202',
    'trigger-test-000000000202@example.com',
    '{}'::jsonb,
    now()
  );
  $$, 'username is required to create profile', 'missing username raises exception')
;

select *
from finish()
;
rollback
;

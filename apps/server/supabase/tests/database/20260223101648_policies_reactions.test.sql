/*
TEST: RLS policies on public.reactions

Verifies RLS policies on reactions table match migration 20260222101637_policies_reactions.sql.

Setup: Requires pgtap extension in extensions schema. Creates test users and reactions.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

-- Create test data schema for cross-role test data
create schema if not exists test_data;

select plan(19)
;

-- Setup: create 2 users (profiles are created by your auth trigger)
-- Use file-unique UUIDs + unique emails to avoid collisions across test files.
insert into auth.users (id, email, raw_user_meta_data, created_at)
values
  ('41111111-1111-1111-1111-111111111111', 'policies-reactions-u1-4111@example.com', '{"username":"react-one"}'::jsonb, now()),
  ('42222222-2222-2222-2222-222222222222', 'policies-reactions-u2-4222@example.com', '{"username":"react-two"}'::jsonb, now());

-- Seed two reactions on the same post (one per user) and capture IDs
create table if not exists test_data.test_reaction_ids (label text primary key, id bigint not null);
truncate table test_data.test_reaction_ids;
grant all
on schema test_data
to anon, authenticated
;
grant all
on table test_data.test_reaction_ids
to anon, authenticated
;

with
    ins as (
        insert into public.reactions(post_id, user_id, type)
        values ('post-1', '41111111-1111-1111-1111-111111111111'::uuid, 'love')
        returning id
    )
    insert into test_data.test_reaction_ids(label, id)
select 'u1_post1', id
from ins
;

with
    ins as (
        insert into public.reactions(post_id, user_id, type)
        values ('post-1', '42222222-2222-2222-2222-222222222222'::uuid, 'like')
        returning id
    )
    insert into test_data.test_reaction_ids(label, id)
select 'u2_post1', id
from ins
;

-- policy existence / shape(pgtap policy helpers)
-- RLS enabled on reactions
select
    ok(
        exists (
            select 1
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where
                n.nspname = 'public'
                and c.relname = 'reactions'
                and c.relrowsecurity is true
        ),
        'RLS is enabled on public.reactions'
    )
;

-- Policies are exactly what we expect (no extras)
select
    policies_are(
        'public',
        'reactions',
        array[
            'reactions_select_public',
            'reactions_insert_own',
            'reactions_update_own',
            'reactions_delete_own'
        ]
    )
;

-- Role scoping checks
select
    policy_roles_are(
        'public',
        'reactions',
        'reactions_select_public',
        array['anon', 'authenticated'],
        'select policy applies to anon + authenticated'
    )
;

select
    policy_roles_are(
        'public',
        'reactions',
        'reactions_insert_own',
        array['authenticated'],
        'insert policy applies only to authenticated'
    )
;

select
    policy_roles_are(
        'public',
        'reactions',
        'reactions_update_own',
        array['authenticated'],
        'update policy applies only to authenticated'
    )
;

select
    policy_roles_are(
        'public',
        'reactions',
        'reactions_delete_own',
        array['authenticated'],
        'delete policy applies only to authenticated'
    )
;

-- Command scoping checks
select
    policy_cmd_is(
        'public',
        'reactions',
        'reactions_insert_own',
        'INSERT',
        'insert policy command is INSERT'
    )
;

select
    policy_cmd_is(
        'public',
        'reactions',
        'reactions_update_own',
        'UPDATE',
        'update policy command is UPDATE'
    )
;

select
    policy_cmd_is(
        'public',
        'reactions',
        'reactions_delete_own',
        'DELETE',
        'delete policy command is DELETE'
    )
;

-- policy behavior
-- As anon: can read reactions (public counting use-case)
set local role anon
;

select
    results_eq(
        $$select count(*) from public.reactions where post_id = 'post-1'$$,
        array[2::bigint],
        'anon can read reactions for counting'
    )
;

-- As anon: cannot insert (RLS blocks)
select throws_like($$
  insert into public.reactions (post_id, user_id, type)
  values ('post-2', '41111111-1111-1111-1111-111111111111'::uuid, 'neutral');
  $$, '%row-level security%', 'anon cannot insert reactions')
;

-- As anon: cannot update others' reactions (RLS silently filters - 0 rows affected)
select
    is_empty(
        format(
            $$update public.reactions set type = 'heartbreak' where id = %s returning id$$,
            (select id from test_data.test_reaction_ids where label = 'u1_post1')
        ),
        'anon cannot update reactions'
    )
;

-- As anon: cannot delete others' reactions (RLS silently filters - 0 rows affected)
select
    is_empty(
        format(
            $$delete from public.reactions where id = %s returning id$$,
            (select id from test_data.test_reaction_ids where label = 'u1_post1')
        ),
        'anon cannot delete reactions'
    )
;

-- As authenticated user1: can insert only as themselves
set local role authenticated
;
set local request.jwt.claim.sub = '41111111-1111-1111-1111-111111111111'
;

select lives_ok($$
  insert into public.reactions (post_id, user_id, type)
  values ('post-2', '41111111-1111-1111-1111-111111111111'::uuid, 'neutral');
  $$, 'user1 can insert own reaction')
;

select throws_like($$
  insert into public.reactions (post_id, user_id, type)
  values ('post-2', '42222222-2222-2222-2222-222222222222'::uuid, 'neutral');
  $$, '%row-level security%', 'user1 cannot insert reaction as another user')
;

-- As authenticated user1: can update own reaction (change type)
select isnt_empty($$
  update public.reactions
  set type = 'heartbreak'
  where post_id = 'post-1'
    and user_id = '41111111-1111-1111-1111-111111111111'::uuid
  returning id
  $$, 'user1 can update own reaction')
;

-- As authenticated user1: cannot update user2 reaction (should affect 0 rows)
select is_empty($$
  update public.reactions
  set type = 'heartbreak'
  where post_id = 'post-1'
    and user_id = '42222222-2222-2222-2222-222222222222'::uuid
  returning id
  $$, 'user1 cannot update another user reaction')
;

-- As authenticated user1: can delete own reaction (remove reaction)
select isnt_empty($$
  delete from public.reactions
  where post_id = 'post-2'
    and user_id = '41111111-1111-1111-1111-111111111111'::uuid
  returning id
  $$, 'user1 can delete own reaction')
;

-- As authenticated user1: cannot delete user2 reaction (should affect 0 rows)
select is_empty($$
  delete from public.reactions
  where post_id = 'post-1'
    and user_id = '42222222-2222-2222-2222-222222222222'::uuid
  returning id
  $$, 'user1 cannot delete another user reaction')
;

select *
from finish()
;

rollback
;

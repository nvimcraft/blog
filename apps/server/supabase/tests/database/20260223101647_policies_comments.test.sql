/*
TEST: RLS policies on public.comments

Verifies RLS policies on comments table match migration 20260222101636_policies_comments.sql.

Setup: Requires pgtap extension in extensions schema. Creates test users and comments.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

-- Create test data schema for cross-role test data
create schema if not exists test_data;

select plan(18)
;

-- Setup (run as default test role, typically privileged)
-- Use file-unique UUIDs + unique emails to avoid collisions across test files.
-- Create 2 users (your auth trigger should create profiles)
insert into auth.users (id, email, raw_user_meta_data, created_at)
values
  ('31111111-1111-1111-1111-111111111111', 'policies-comments-u1-3111@example.com', '{"username":"user-one"}'::jsonb, now()),
  ('32222222-2222-2222-2222-222222222222', 'policies-comments-u2-3222@example.com', '{"username":"user-two"}'::jsonb, now());

-- Seed 3 comments in post-1:
-- - u1_active (active)
-- - u1_deleted (deleted)
-- - u2_active (active)
create table if not exists test_data.test_comment_ids (label text primary key, id bigint not null);
truncate table test_data.test_comment_ids;
grant all
on schema test_data
to anon, authenticated
;
grant all
on table test_data.test_comment_ids
to anon, authenticated
;

with
    ins as (
        insert into public.comments(post_id, user_id, content, deleted_at)
        values
            (
                'post-1',
                '31111111-1111-1111-1111-111111111111'::uuid,
                'hello from u1',
                null
            )
        returning id
    )
    insert into test_data.test_comment_ids(label, id)
select 'u1_active', id
from ins
;

with
    ins as (
        insert into public.comments(post_id, user_id, content, deleted_at)
        values
            (
                'post-1',
                '31111111-1111-1111-1111-111111111111'::uuid,
                'u1 deleted',
                now()
            )
        returning id
    )
    insert into test_data.test_comment_ids(label, id)
select 'u1_deleted', id
from ins
;

with
    ins as (
        insert into public.comments(post_id, user_id, content, deleted_at)
        values
            (
                'post-1',
                '32222222-2222-2222-2222-222222222222'::uuid,
                'hello from u2',
                null
            )
        returning id
    )
    insert into test_data.test_comment_ids(label, id)
select 'u2_active', id
from ins
;

-- policy existence / shape(pgtap policy helpers)
-- RLS enabled on comments
select
    ok(
        exists (
            select 1
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where
                n.nspname = 'public'
                and c.relname = 'comments'
                and c.relrowsecurity is true
        ),
        'RLS is enabled on public.comments'
    )
;

-- Policies are exactly what we expect (no extras)
select
    policies_are(
        'public',
        'comments',
        array[
            'comments_select_public_active',
            'comments_select_authenticated',
            'comments_insert_own',
            'comments_update_own'
        ]
    )
;

-- No DELETE policy exists (forces soft deletes)
select
    ok(
        not exists (
            select 1
            from pg_policies
            where schemaname = 'public' and tablename = 'comments' and cmd = 'DELETE'
        ),
        'no DELETE policy exists for public.comments'
    )
;

-- Role + command scoping sanity checks
select
    policy_roles_are(
        'public',
        'comments',
        'comments_select_public_active',
        array['anon'],
        'public select policy applies only to anon'
    )
;

select
    policy_roles_are(
        'public',
        'comments',
        'comments_select_authenticated',
        array['authenticated'],
        'authenticated select policy applies only to authenticated'
    )
;

select
    policy_cmd_is(
        'public',
        'comments',
        'comments_insert_own',
        'INSERT',
        'insert policy command is INSERT'
    )
;

select
    policy_cmd_is(
        'public',
        'comments',
        'comments_update_own',
        'UPDATE',
        'update policy command is UPDATE'
    )
;

-- policy behavior
-- As anon: can read only active comments
set local role anon
;

select
    results_eq(
        $$select count(*) from public.comments where post_id = 'post-1'$$,
        array[2::bigint],
        'anon sees only active comments'
    )
;

select
    results_eq(
        $$select count(*) from public.comments where post_id = 'post-1' and deleted_at is not null$$,
        array[0::bigint],
        'anon sees no deleted comments'
    )
;

-- As authenticated user1: sees active OR their own (including deleted)
set local role authenticated
;
set local request.jwt.claim.sub = '31111111-1111-1111-1111-111111111111'
;

select
    results_eq(
        $$select count(*) from public.comments where post_id = 'post-1'$$,
        array[3::bigint],
        'user1 sees active comments + their own deleted comment'
    )
;

-- As authenticated user2: sees only active (no deleted owned)
set local request.jwt.claim.sub = '32222222-2222-2222-2222-222222222222'
;

select
    results_eq(
        $$select count(*) from public.comments where post_id = 'post-1'$$,
        array[2::bigint],
        'user2 sees only active comments'
    )
;

-- As authenticated user1: insert only as themselves; deleted_at must be null
set local request.jwt.claim.sub = '31111111-1111-1111-1111-111111111111'
;

select
    lives_ok(
        $$
  insert into public.comments (post_id, user_id, content, deleted_at)
  values ('post-2', '31111111-1111-1111-1111-111111111111'::uuid, 'u1 new comment', null);
  $$,
        'user1 can insert their own comment'
    )
;

select throws_like($$
  insert into public.comments (post_id, user_id, content, deleted_at)
  values ('post-2', '32222222-2222-2222-2222-222222222222'::uuid, 'spoof u2', null);
  $$, '%row-level security%', 'user1 cannot insert comment as another user')
;

-- Update: user1 can update own ACTIVE comment
select
    isnt_empty(
        format(
            $$update public.comments set content = 'u1 edited' where id = %s returning id$$,
            (select id from test_data.test_comment_ids where label = 'u1_active')
        ),
        'user1 can update own active comment'
    )
;

-- Update: user1 cannot update someone else’s comment (0 rows)
select
    is_empty(
        format(
            $$update public.comments set content = 'hacked' where id = %s returning id$$,
            (select id from test_data.test_comment_ids where label = 'u2_active')
        ),
        'user1 cannot update someone else’s comment'
    )
;

-- Soft delete: user1 can set deleted_at on own active comment
select
    isnt_empty(
        format(
            $$update public.comments set deleted_at = now() where id = %s returning id$$,
            (select id from test_data.test_comment_ids where label = 'u1_active')
        ),
        'user1 can soft-delete own active comment'
    )
;

-- After soft delete, user1 cannot edit it (UPDATE policy requires deleted_at is null)
select
    is_empty(
        format(
            $$update public.comments set content = 'edit after delete' where id = %s returning id$$,
            (select id from test_data.test_comment_ids where label = 'u1_active')
        ),
        'user1 cannot edit own comment after soft delete'
    )
;

-- No hard delete from client: DELETE should fail (no DELETE policy, RLS silently
-- filters)
select
    is_empty(
        format(
            $$delete from public.comments where id = %s returning id$$,
            (select id from test_data.test_comment_ids where label = 'u2_active')
        ),
        'hard delete is not allowed (no DELETE policy)'
    )
;

select *
from finish()
;

rollback
;

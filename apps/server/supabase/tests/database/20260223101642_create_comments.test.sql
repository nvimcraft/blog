/*
TEST: public.comments

Verifies the comments table structure matches migration 20260222101631_create_comments.sql.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

-- Setup: Ensure pgTAP exists
create extension if not exists pgtap with schema extensions;

select plan(30)
;

-- Table exists
select has_table('public', 'comments', 'public.comments table exists')
;

-- Required columns exist
select has_column('public', 'comments', 'id', 'comments.id exists')
;
select has_column('public', 'comments', 'post_id', 'comments.post_id exists')
;
select has_column('public', 'comments', 'user_id', 'comments.user_id exists')
;
select has_column('public', 'comments', 'content', 'comments.content exists')
;
select has_column('public', 'comments', 'created_at', 'comments.created_at exists')
;
select has_column('public', 'comments', 'updated_at', 'comments.updated_at exists')
;
select has_column('public', 'comments', 'deleted_at', 'comments.deleted_at exists')
;

-- Column types
select col_type_is('public', 'comments', 'id', 'bigint', 'id is bigint')
;
select col_type_is('public', 'comments', 'post_id', 'text', 'post_id is text')
;
select col_type_is('public', 'comments', 'user_id', 'uuid', 'user_id is uuid')
;
select col_type_is('public', 'comments', 'content', 'text', 'content is text')
;
select
    col_type_is(
        'public',
        'comments',
        'created_at',
        'timestamp with time zone',
        'created_at is timestamptz'
    )
;
select
    col_type_is(
        'public',
        'comments',
        'updated_at',
        'timestamp with time zone',
        'updated_at is timestamptz'
    )
;
select
    col_type_is(
        'public',
        'comments',
        'deleted_at',
        'timestamp with time zone',
        'deleted_at is timestamptz'
    )
;

-- NOT NULL expectations
select col_not_null('public', 'comments', 'id', 'id is not null')
;
select col_not_null('public', 'comments', 'post_id', 'post_id is not null')
;
select col_not_null('public', 'comments', 'user_id', 'user_id is not null')
;
select col_not_null('public', 'comments', 'content', 'content is not null')
;
select col_not_null('public', 'comments', 'created_at', 'created_at is not null')
;
select col_not_null('public', 'comments', 'updated_at', 'updated_at is not null')
;
-- deleted_at intentionally nullable (soft delete), so no not-null check.
-- Primary key on id
select has_pk('public', 'comments', 'comments has a primary key')
;
select col_is_pk('public', 'comments', 'id', 'id is the primary key')
;

-- FK: user_id references public.profiles(id) ON DELETE RESTRICT
-- confdeltype: 'r' = RESTRICT
select
    ok(
        exists (
            select 1
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            join pg_class rt on rt.oid = c.confrelid
            join pg_namespace rn on rn.oid = rt.relnamespace
            where
                c.contype = 'f'
                and n.nspname = 'public'
                and t.relname = 'comments'
                and rn.nspname = 'public'
                and rt.relname = 'profiles'
                and c.confdeltype = 'r'
        ),
        'comments.user_id references public.profiles(id) ON DELETE RESTRICT'
    )
;

-- CHECK constraint for content exists
select
    ok(
        exists (
            select 1
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            where c.contype = 'c' and n.nspname = 'public' and t.relname = 'comments'
        ),
        'content CHECK constraint exists'
    )
;

-- Defaults for timestamps
select col_has_default('public', 'comments', 'created_at', 'created_at has default')
;
select col_has_default('public', 'comments', 'updated_at', 'updated_at has default')
;

-- Indexes exist
select
    ok(
        to_regclass('public.comments_post_id_created_at_idx') is not null,
        'index comments_post_id_created_at_idx exists'
    )
;

select
    ok(
        to_regclass('public.comments_user_id_created_at_idx') is not null,
        'index comments_user_id_created_at_idx exists'
    )
;

-- Partial index existence + predicate:
-- Use pg_indexes.indexdef (reconstructed CREATE INDEX) which includes the WHERE
-- clause. [3](https://www.postgresql.org/docs/current/view-pg-indexes.html)
select
    ok(
        exists (
            select 1
            from pg_indexes
            where
                schemaname = 'public'
                and indexname = 'comments_active_post_id_created_at_idx'
                and indexdef ilike '%where%deleted_at%is%null%'
        ),
        'partial index comments_active_post_id_created_at_idx exists with predicate deleted_at is null'
    )
;

select *
from finish()
;
rollback
;

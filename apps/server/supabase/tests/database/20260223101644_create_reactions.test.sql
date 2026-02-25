/*
TEST: public.reactions

Verifies the reactions table structure matches migration 20260222101633_create_reactions.sql.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

-- Setup: Ensure pgTAP exists
create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

select plan(28)
;

-- Table exists
select has_table('public', 'reactions', 'public.reactions table exists')
;

-- Required columns exist
select has_column('public', 'reactions', 'id', 'reactions.id exists')
;
select has_column('public', 'reactions', 'post_id', 'reactions.post_id exists')
;
select has_column('public', 'reactions', 'user_id', 'reactions.user_id exists')
;
select has_column('public', 'reactions', 'type', 'reactions.type exists')
;
select has_column('public', 'reactions', 'created_at', 'reactions.created_at exists')
;
select has_column('public', 'reactions', 'updated_at', 'reactions.updated_at exists')
;

-- Column types
select col_type_is('public', 'reactions', 'id', 'bigint', 'id is bigint')
;
select col_type_is('public', 'reactions', 'post_id', 'text', 'post_id is text')
;
select col_type_is('public', 'reactions', 'user_id', 'uuid', 'user_id is uuid')
;
select
    col_type_is(
        'public', 'reactions', 'type', 'reaction_type', 'type is reaction_type enum'
    )
;
select
    col_type_is(
        'public',
        'reactions',
        'created_at',
        'timestamp with time zone',
        'created_at is timestamptz'
    )
;
select
    col_type_is(
        'public',
        'reactions',
        'updated_at',
        'timestamp with time zone',
        'updated_at is timestamptz'
    )
;

-- NOT NULL expectations
select col_not_null('public', 'reactions', 'id', 'id is not null')
;
select col_not_null('public', 'reactions', 'post_id', 'post_id is not null')
;
select col_not_null('public', 'reactions', 'user_id', 'user_id is not null')
;
select col_not_null('public', 'reactions', 'type', 'type is not null')
;
select col_not_null('public', 'reactions', 'created_at', 'created_at is not null')
;
select col_not_null('public', 'reactions', 'updated_at', 'updated_at is not null')
;

-- Primary key on id
select has_pk('public', 'reactions', 'reactions has a primary key')
;
select col_is_pk('public', 'reactions', 'id', 'id is the primary key')
;

-- id is GENERATED ALWAYS AS IDENTITY (attidentity = 'a')
-- Identity columns are created via GENERATED ... AS IDENTITY.
select
    ok(
        exists (
            select 1
            from pg_attribute a
            join pg_class c on c.oid = a.attrelid
            join pg_namespace n on n.oid = c.relnamespace
            where
                n.nspname = 'public'
                and c.relname = 'reactions'
                and a.attname = 'id'
                and a.attidentity = 'a'  -- 'a' = GENERATED ALWAYS AS IDENTITY
        ),
        'id is GENERATED ALWAYS AS IDENTITY'
    )
;

-- FK: user_id references public.profiles(id) ON DELETE CASCADE
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
                and t.relname = 'reactions'
                and rn.nspname = 'public'
                and rt.relname = 'profiles'
                and c.confdeltype = 'c'  -- cascade
        ),
        'reactions.user_id references public.profiles(id) ON DELETE CASCADE'
    )
;

-- Unique constraint: (post_id, user_id)
select
    extensions.ok(
        exists (
            select 1
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            where c.contype = 'u' and n.nspname = 'public' and t.relname = 'reactions'
        ),
        'unique(post_id, user_id) exists'
    )
;

-- Defaults for timestamps
select col_has_default('public', 'reactions', 'created_at', 'created_at has default')
;
select col_has_default('public', 'reactions', 'updated_at', 'updated_at has default')
;

-- Indexes exist
select
    ok(
        to_regclass('public.reactions_post_id_idx') is not null,
        'index reactions_post_id_idx exists'
    )
;

select
    ok(
        to_regclass('public.reactions_user_id_idx') is not null,
        'index reactions_user_id_idx exists'
    )
;

select *
from finish()
;
rollback
;

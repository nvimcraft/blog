/*
TEST: public.profiles

Verifies the profiles table structure matches migration 20260222101629_create_profiles.sql.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

-- Setup: Ensure pgTAP exists
create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

select plan(21)
;

-- citext extension exists
select extensions.has_extension('citext', 'citext extension is installed')
;

-- Table exists
select extensions.has_table('public', 'profiles', 'public.profiles table exists')
;

-- Columns exist
select extensions.has_column('public', 'profiles', 'id', 'profiles.id exists')
;
select
    extensions.has_column('public', 'profiles', 'username', 'profiles.username exists')
;
select
    extensions.has_column(
        'public', 'profiles', 'created_at', 'profiles.created_at exists'
    )
;
select
    extensions.has_column(
        'public', 'profiles', 'updated_at', 'profiles.updated_at exists'
    )
;

-- Column types
select extensions.col_type_is('public', 'profiles', 'id', 'uuid', 'id is uuid')
;
select
    extensions.col_type_is(
        'public', 'profiles', 'username', 'citext', 'username is citext'
    )
;
select
    extensions.col_type_is(
        'public',
        'profiles',
        'created_at',
        'timestamp with time zone',
        'created_at is timestamptz'
    )
;
select
    extensions.col_type_is(
        'public',
        'profiles',
        'updated_at',
        'timestamp with time zone',
        'updated_at is timestamptz'
    )
;

-- NOT NULL constraints
select extensions.col_not_null('public', 'profiles', 'id', 'id is not null')
;
select extensions.col_not_null('public', 'profiles', 'username', 'username is not null')
;
select
    extensions.col_not_null(
        'public', 'profiles', 'created_at', 'created_at is not null'
    )
;
select
    extensions.col_not_null(
        'public', 'profiles', 'updated_at', 'updated_at is not null'
    )
;

-- Primary key
select extensions.has_pk('public', 'profiles', 'profiles has a primary key')
;
select extensions.col_is_pk('public', 'profiles', 'id', 'id is the primary key')
;

-- Unique constraint (fully qualified and casted)
select
    extensions.ok(
        exists (
            select 1
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            where
                c.contype = 'u'
                and n.nspname = 'public'
                and t.relname = 'profiles'
                and c.conkey = array[
                    (
                        select attnum
                        from pg_attribute
                        where attrelid = t.oid and attname = 'username'
                    )
                ]
        ),
        'username is unique'
    )
;

-- Foreign key
select
    extensions.ok(
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
                and t.relname = 'profiles'
                and rn.nspname = 'auth'
                and rt.relname = 'users'
                and c.confdeltype = 'c'
        ),
        'profiles.id references auth.users(id) ON DELETE CASCADE'
    )
;

-- Username CHECK constraint exists
select
    extensions.ok(
        exists (
            select 1
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            where c.contype = 'c' and n.nspname = 'public' and t.relname = 'profiles'
        ),
        'username CHECK constraint exists'
    )
;

-- Defaults
select
    extensions.col_has_default(
        'public', 'profiles', 'created_at', 'created_at has a default'
    )
;
select
    extensions.col_has_default(
        'public', 'profiles', 'updated_at', 'updated_at has a default'
    )
;

select *
from extensions.finish()
;

rollback
;

/*
TEST: public.newsletter_subscriptions

Verifies the newsletter_subscriptions table structure matches
migration 20260222101638_create_newsletter_subscriptions.sql.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

select plan(8)
;

-- Table exists
select
    ok(
        exists (
            select 1
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where
                n.nspname = 'public'
                and c.relname = 'newsletter_subscriptions'
                and c.relkind = 'r'
        ),
        'Table public.newsletter_subscriptions exists'
    )
;

-- Columns exist
select
    ok(
        exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'id'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'email'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'token'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'verified'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'created_at'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'verified_at'
        )
        and exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'consumed_at'
        ),
        'All required columns exist'
    )
;

-- Column types
select
    ok(
        (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'id'
        )
        = 'uuid'
        and (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'email'
        )
        = 'USER-DEFINED'
        and (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'token'
        )
        = 'uuid'
        and (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'verified'
        )
        = 'boolean'
        and (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'created_at'
        )
        = 'timestamp with time zone',
        'Column types are correct'
    )
;

-- NOT NULL constraints
select
    ok(
        (
            select is_nullable
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'id'
        )
        = 'NO'
        and (
            select is_nullable
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'email'
        )
        = 'NO'
        and (
            select is_nullable
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'token'
        )
        = 'NO'
        and (
            select is_nullable
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'verified'
        )
        = 'NO'
        and (
            select is_nullable
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'created_at'
        )
        = 'NO',
        'NOT NULL constraints are applied'
    )
;

-- Primary key
select
    ok(
        exists (
            select 1
            from information_schema.table_constraints
            where
                constraint_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and constraint_type = 'PRIMARY KEY'
        ),
        'Primary key exists'
    )
;

-- Unique constraints
select
    ok(
        (
            select count(*)
            from information_schema.table_constraints
            where
                constraint_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and constraint_type = 'UNIQUE'
        )
        >= 2,
        'Unique constraints exist for email and token'
    )
;

-- CHECK constraint for email format
select
    ok(
        exists (
            select 1
            from information_schema.check_constraints
            where constraint_schema = 'public' and constraint_name like '%email%'
        ),
        'CHECK constraint for email format exists'
    )
;

-- Indexes exist
select
    ok(
        exists (
            select 1
            from pg_indexes
            where
                schemaname = 'public'
                and tablename = 'newsletter_subscriptions'
                and indexname like '%token%'
        )
        and exists (
            select 1
            from pg_indexes
            where
                schemaname = 'public'
                and tablename = 'newsletter_subscriptions'
                and indexname like '%email%'
        ),
        'Indexes exist for token and email'
    )
;

select *
from finish()
;

rollback
;

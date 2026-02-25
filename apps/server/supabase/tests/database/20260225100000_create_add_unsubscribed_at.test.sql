/*
TEST: public.newsletter_subscriptions.unsubscribed_at column

Verifies the unsubscribed_at column was added by migration
20260225100000_create_add_unsubscribed_at.sql.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

create schema if not exists test_data;

grant all
on schema test_data
to postgres, anon, authenticated, service_role
;
grant all
on all tables in schema test_data
to postgres, anon, authenticated, service_role
;
grant all
on all sequences in schema test_data
to postgres, anon, authenticated, service_role
;

select plan(2)
;

-- column exists
select
    ok(
        exists (
            select 1
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'unsubscribed_at'
        ),
        'Column unsubscribed_at exists'
    )
;

-- column type is timestamptz
select
    ok(
        (
            select data_type
            from information_schema.columns
            where
                table_schema = 'public'
                and table_name = 'newsletter_subscriptions'
                and column_name = 'unsubscribed_at'
        )
        = 'timestamp with time zone',
        'Column unsubscribed_at is timestamptz'
    )
;

select *
from finish()
;

rollback
;

/*
TEST: extensions schema

Verifies the extensions schema and citext extension are correctly installed per
migration 20260222101628_create_extensions_schema.sql.

Setup: Creates pgtap extension in extensions schema.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

set local search_path = extensions, public
;

select plan(4)
;

-- Schema exists
select has_schema('extensions', 'extensions schema exists')
;

-- citext extension is installed
select has_extension('citext', 'citext extension is installed')
;

-- citext is installed into the extensions schema
select
    ok(
        exists (
            select 1
            from pg_extension e
            join pg_namespace n on n.oid = e.extnamespace
            where e.extname = 'citext' and n.nspname = 'extensions'
        ),
        'citext is installed in extensions schema'
    )
;

-- Invariant check: no regular tables exist in extensions schema
select
    ok(
        (
            select count(*) = 0
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'extensions' and c.relkind = 'r'
        ),
        'extensions schema has no regular tables'
    )
;

select *
from finish()
;

rollback
;

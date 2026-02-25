/*
TEST: public.reaction_type enum

Verifies the reaction_type enum exists with the correct labels.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

-- Setup: Ensure pgTAP exists
create extension if not exists pgtap with schema extensions;

select plan(3)
;

-- Enum exists (schema-qualified)
-- pgTAP supports has_enum(schema, enum, desc).
select has_enum('public', 'reaction_type', 'public.reaction_type enum exists')
;

-- Labels match exactly (closed set) in declared order
-- Avoid array comparison to prevent collation ambiguity; compare ordered rows
-- and force a deterministic collation for string comparison.
select results_eq($$
  select (e.enumlabel::text collate "C") as label
  from pg_type t
  join pg_namespace n on n.oid = t.typnamespace
  join pg_enum e on e.enumtypid = t.oid
  where n.nspname = 'public'
    and t.typname = 'reaction_type'
  order by e.enumsortorder
  $$, $$
  values
    ('love'::text collate "C"),
    ('like'::text collate "C"),
    ('neutral'::text collate "C"),
    ('heartbreak'::text collate "C")
  $$, 'reaction_type labels are exactly [love, like, neutral, heartbreak] in order')
;

-- Count is exactly 4 (guards against accidental additions)
select
    is (
        (
            select count(*)
            from pg_type t
            join pg_namespace n on n.oid = t.typnamespace
            join pg_enum e on e.enumtypid = t.oid
            where n.nspname = 'public' and t.typname = 'reaction_type'
        ),
        4::bigint,
        'reaction_type has exactly 4 values'
    )
;

select *
from finish()
;
rollback
;

/*
TEST: public.update_updated_at trigger function

Verifies the update_updated_at trigger function and its triggers on
profiles, comments, and reactions tables.

Setup: Requires pgtap extension in extensions schema.
*/
begin
;

create schema if not exists extensions;
create extension if not exists pgtap with schema extensions;

select plan(7)
;

-- Function exists + safety properties (SECURITY DEFINER + pinned search_path)
-- pg_proc includes prosecdef and proconfig.
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'update_updated_at'
        ),
        'public.update_updated_at() exists'
    )
;

select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            join pg_type t on t.oid = p.prorettype
            where
                n.nspname = 'public'
                and p.proname = 'update_updated_at'
                and t.typname = 'trigger'
        ),
        'public.update_updated_at() returns trigger'
    )
;

select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where
                n.nspname = 'public'
                and p.proname = 'update_updated_at'
                and p.prosecdef is true
        ),
        'public.update_updated_at() is SECURITY DEFINER'
    )
;

-- Robust: accept search_path= or search_path=""
select
    ok(
        exists (
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            cross join lateral unnest(p.proconfig) cfg
            where
                n.nspname = 'public'
                and p.proname = 'update_updated_at'
                and cfg like 'search_path=%'
                and length(btrim(regexp_replace(cfg, '^search_path=', ''), '"''')) = 0
        ),
        'public.update_updated_at() sets search_path to empty'
    )
;

-- Triggers exist on the expected tables
-- information_schema.triggers columns are documented by PostgreSQL.
select
    ok(
        exists (
            select 1
            from information_schema.triggers t
            where
                t.trigger_name = 'update_profiles_updated_at'
                and t.event_object_schema = 'public'
                and t.event_object_table = 'profiles'
                and t.event_manipulation = 'UPDATE'
                and t.action_timing = 'BEFORE'
                and t.action_orientation = 'ROW'
                and (
                    t.action_statement ilike '%execute function%update_updated_at()%'
                    or t.action_statement
                    ilike '%execute function public.update_updated_at()%'
                )
        ),
        'trigger update_profiles_updated_at exists (BEFORE UPDATE on public.profiles)'
    )
;

select
    ok(
        exists (
            select 1
            from information_schema.triggers t
            where
                t.trigger_name = 'update_comments_updated_at'
                and t.event_object_schema = 'public'
                and t.event_object_table = 'comments'
                and t.event_manipulation = 'UPDATE'
                and t.action_timing = 'BEFORE'
                and t.action_orientation = 'ROW'
                and (
                    t.action_statement ilike '%execute function%update_updated_at()%'
                    or t.action_statement
                    ilike '%execute function public.update_updated_at()%'
                )
        ),
        'trigger update_comments_updated_at exists (BEFORE UPDATE on public.comments)'
    )
;

select
    ok(
        exists (
            select 1
            from information_schema.triggers t
            where
                t.trigger_name = 'update_reactions_updated_at'
                and t.event_object_schema = 'public'
                and t.event_object_table = 'reactions'
                and t.event_manipulation = 'UPDATE'
                and t.action_timing = 'BEFORE'
                and t.action_orientation = 'ROW'
                and (
                    t.action_statement ilike '%execute function%update_updated_at()%'
                    or t.action_statement
                    ilike '%execute function public.update_updated_at()%'
                )
        ),
        'trigger update_reactions_updated_at exists (BEFORE UPDATE on public.reactions)'
    )
;

select *
from extensions.finish()
;

rollback
;

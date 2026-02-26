/*
FUNCTION: update_updated_at

ROLE IN THE SYSTEM:
  Centralized trigger function to automatically maintain updated_at
  timestamps for mutable rows.

DESIGN NOTES:
  - Application code must not manually manage updated_at.
  - This function is attached to profiles, comments, and reactions tables.
  - Special case: On comments table, skip updated_at during soft deletes
    (when deleted_at is set) to preserve the original edit timestamp.
*/
create or replace function public.update_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
BEGIN
  -- Skip updated_at update during soft deletes (only for comments table)
  IF TG_TABLE_NAME = 'comments' THEN
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      RETURN NEW;
    END IF;
  END IF;

  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$
;

-- TRIGGERS
-- Automatically update updated_at on profile changes (e.g. username updates)
create or replace trigger update_profiles_updated_at
  before update on public.profiles
  for each row
execute function public.update_updated_at();

-- Automatically update updated_at on comment edits
create or replace trigger update_comments_updated_at
  before update on public.comments
  for each row
execute function public.update_updated_at();

-- Automatically update updated_at on reaction changes
create or replace trigger update_reactions_updated_at
  before update on public.reactions
  for each row
execute function public.update_updated_at();

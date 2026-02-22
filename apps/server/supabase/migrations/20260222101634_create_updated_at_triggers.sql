/*
FUNCTION: update_updated_at

ROLE IN THE SYSTEM:
  Centralized trigger function to automatically maintain updated_at
  timestamps for mutable rows.

DESIGN NOTES:
  - Application code must not manually manage updated_at.
  - This function is reused across multiple tables.
  - Soft deletes (deleted_at) are treated as a separate lifecycle event.
*/
create or replace function public.update_updated_at()
returns trigger
security definer
set search_path = ''
as $$
begin
  -- Do not overwrite updated_at during soft deletes on comments
  if tg_table_name = 'comments'
     and old.deleted_at is null
     and new.deleted_at is not null then
    return new;
  end if;

  new.updated_at = now();
  return new;
end;
$$
language plpgsql
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

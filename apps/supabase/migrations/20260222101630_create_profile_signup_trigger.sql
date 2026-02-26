/*
FUNCTION: public.handle_new_user

ROLE IN THE SYSTEM:
  Creates the required public.profiles row when a new auth.users row is created.

WHY THIS EXISTS:
  - public.profiles is the public identity surface (username) used by comments
    and reactions.
  - comments/reactions reference profiles(id), so a profile row must exist
    immediately after signup.

DESIGN INVARIANTS:
  - Must be safe to run multiple times (idempotent).
  - Must not break signup due to duplicate inserts.
  - Must not rely on mutable search_path resolution.

NOTE:
  - If username is missing from raw_user_meta_data, this function raises an
    exception to fail fast (since profiles.username is NOT NULL in this design).
    If you later support OAuth without collecting username at signup, replace
    this with a placeholder strategy.
*/
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (new.raw_user_meta_data ->> 'username') is null then
    raise exception 'username is required to create profile';
  end if;

  insert into public.profiles (id, username)
  values (new.id, new.raw_user_meta_data ->> 'username')
  on conflict (id) do nothing;

  return new;
end;
$$
;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

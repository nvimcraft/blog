/*
POLICIES: public.profiles

Goal:
  - Public can read usernames for attribution.
  - Authenticated users can update only their own profile.
  - Inserts are allowed only for the owner (useful for non-trigger flows),
    but in your system profiles are primarily created by auth trigger.
*/
-- Public read access (safe columns only exist in this table)
drop policy if exists "profiles_select_public" on public.profiles;
create policy "profiles_select_public"
on public.profiles
for select
to anon, authenticated
using (true);

-- Allow users to insert their own profile row (optional but harmless)
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = (select auth.uid()));

-- Allow users to update their own profile
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

set local lock_timeout = '10s'
;
alter table public.profiles enable row level security;

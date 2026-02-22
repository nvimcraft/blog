/*
POLICIES: public.reactions

Goal:
  - Public read: allow counting reactions per post.
  - Authenticated users can insert/update/delete only their own reaction.
*/
alter table public.reactions enable row level security;

-- Public read access (safe: only counts/types/user_id)
drop policy if exists "reactions_select_public" on public.reactions;
create policy "reactions_select_public"
on public.reactions
for select
to anon, authenticated
using (true);

-- Insert own reaction
drop policy if exists "reactions_insert_own" on public.reactions;
create policy "reactions_insert_own"
on public.reactions
for insert
to authenticated
with check (user_id = (select auth.uid()));

-- Update own reaction
drop policy if exists "reactions_update_own" on public.reactions;
create policy "reactions_update_own"
on public.reactions
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Delete own reaction (remove reaction)
drop policy if exists "reactions_delete_own" on public.reactions;
create policy "reactions_delete_own"
on public.reactions
for delete
to authenticated
using (user_id = (select auth.uid()));

/*
POLICIES: public.comments

Goal:
  - Public read: only active comments (deleted_at is null).
  - Authenticated users can:
      * insert their own comments
      * edit their own active comments
      * soft-delete their own active comments (set deleted_at)
  - No hard deletes from client; use soft delete only.
  - Owners may still see their own deleted comments (required to avoid RLS
    soft-delete edge cases where SELECT policies can block UPDATE). 
*/
alter table public.comments enable row level security;

-- SELECT: anon can read only active
drop policy if exists "comments_select_public_active" on public.comments;
create policy "comments_select_public_active"
on public.comments
for select
to anon
using (deleted_at is null);

-- SELECT: authenticated can read active OR their own (including deleted)
drop policy if exists "comments_select_authenticated" on public.comments;
create policy "comments_select_authenticated"
on public.comments
for select
to authenticated
using (
  deleted_at is null
  or user_id = (select auth.uid())
);

-- INSERT: authenticated users can create comments only as themselves
drop policy if exists "comments_insert_own" on public.comments;
create policy "comments_insert_own"
on public.comments
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and deleted_at is null
);

-- UPDATE: authenticated users can edit/soft-delete their own active comments
drop policy if exists "comments_update_own" on public.comments;
create policy "comments_update_own"
on public.comments
for update
to authenticated
using (
  user_id = (select auth.uid())
  and deleted_at is null
)
with check (
  user_id = (select auth.uid())
);

-- No DELETE policy (forces soft deletes)

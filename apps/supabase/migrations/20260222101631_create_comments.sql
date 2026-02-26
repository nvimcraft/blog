/*
TABLE: public.comments

ROLE IN THE SYSTEM:
  Stores user-generated comments for posts sourced from local Markdown.
  Posts are not database entities; they are identified by a stable logical ID.

CORE INVARIANTS (DO NOT VIOLATE):
  - Comments are owned by profiles.id (stable UUID), not by username (mutable).
  - Post linkage uses a logical identifier (post_id) rather than a foreign key.
  - Soft delete is implemented via deleted_at; rows are retained for moderation.

POST IDENTIFICATION:
  - post_id is derived from Markdown (slug/frontmatter ID/canonical path).
  - No FK exists by design; referential integrity is enforced in application code.

USER LIFECYCLE NOTE:
  - FK points to public.profiles because the app needs public identity.
  - Deleting users may require an explicit strategy (cascade, set null,
    anonymize, or restrict). Do not change FK actions casually.
*/
create table public.comments (
  id bigint generated always as identity primary key,

  post_id text not null,

  user_id uuid not null
    references public.profiles(id)
    on delete restrict,

  content text not null
    check (
      char_length(trim(content)) > 0
      and char_length(content) <= 2000
    ),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  deleted_at timestamptz
);

-- Recommended indexes (schema concern, not policy):
create index if not exists comments_post_id_created_at_idx
  on public.comments (post_id, created_at desc);

create index if not exists comments_user_id_created_at_idx
  on public.comments (user_id, created_at desc);

-- Helps "active comments" queries (soft-delete pattern)
create index if not exists comments_active_post_id_created_at_idx
  on public.comments (post_id, created_at desc)
  where deleted_at is null;

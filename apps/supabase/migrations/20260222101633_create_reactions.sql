/*
TABLE: public.reactions

ROLE IN THE SYSTEM:
  Stores lightweight user reactions to posts.

CORE INVARIANTS (DO NOT VIOLATE):
  - A user may have at most one reaction per post.
  - Reactions are owned by user identity (profiles.id), not username.
  - Posts are referenced by a logical identifier derived from Markdown.

POST IDENTIFICATION:
  - post_id is a stable logical identifier (slug/frontmatter ID/path).
  - No foreign key exists by design; posts are file-based content.

USER LIFECYCLE RULES:
  - Reactions are ephemeral and should not block user deletion.
  - When a user is deleted, their reactions are deleted automatically.

MUTABILITY MODEL:
  - Reaction type is mutable (users may change their reaction).
  - Deleting a reaction removes the row entirely (no soft delete).
*/
create table public.reactions (
  id bigint generated always as identity primary key,

  post_id text not null,

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  type reaction_type not null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (post_id, user_id)
);

-- Recommended indexes for aggregation queries
create index if not exists reactions_post_id_idx
  on public.reactions (post_id);

create index if not exists reactions_user_id_idx
  on public.reactions (user_id);

/*
TABLE: public.profiles

ROLE IN THE SYSTEM:
  This table is the ONLY public-facing representation of a user.
  It exists to decouple public identity from Supabase Auth internals.

WHY THIS TABLE EXISTS (READ THIS BEFORE CHANGING ANYTHING):
  - auth.users contains sensitive authentication data (email, password,
    providers, tokens) and must never be queried directly from client code.
  - public.profiles provides a deliberately minimal identity surface used for:
      - comment attribution
      - reactions
      - any public-facing user reference
  - Email, password, and auth metadata are intentionally excluded and must
    remain in auth.users only.

CORE INVARIANTS (DO NOT VIOLATE):
  - There is a strict 1:1 relationship with auth.users via a shared UUID.
  - profiles.id is the canonical, stable identifier for a user.
  - User-facing features MUST reference profiles.id, not username.
  - Usernames are mutable; identity is not.

USERNAME BEHAVIOR (INTENTIONAL DESIGN):
  - Usernames are allowed to change without breaking historical data.
  - Case-insensitive uniqueness is enforced via CITEXT.
  - Validation rules are intentionally strict to prevent ambiguity and abuse:
      - 4–30 characters
      - alphanumeric segments
      - single hyphens between segments only
  - Never rely on username for authorization, ownership, or joins.

SECURITY & PRIVACY BOUNDARY:
  - This table is safe to expose only after explicit RLS policies are applied.
  - RLS and policies are intentionally defined in separate migrations to keep
    schema and authorization concerns isolated and auditable.
  - Absence of RLS here is deliberate, not an omission.

LIFECYCLE & DATA HYGIENE:
  - ON DELETE CASCADE ensures no orphaned profiles when auth.users is removed.
  - created_at captures initial profile creation.
  - updated_at is expected to be maintained via trigger in a later migration;
    application code should not manage this manually.

OPERATIONAL NOTES:
  - The citext extension MUST exist before this migration runs.
  - If this table is referenced for authentication or authorization logic,
    the system design has been violated.

Auth-related fields must not be added to this table.
*/
create table public.profiles (
  id uuid primary key
    references auth.users(id)
    on delete cascade,

  username citext not null unique
    check (
      char_length(username) between 4 and 30
      and username ~ '^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$'
    ),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

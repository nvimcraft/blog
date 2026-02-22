/*
TYPE: reaction_type

ROLE IN THE SYSTEM:
  Enumerates all supported reaction types for posts.

DESIGN INVARIANT:
  - This is a closed set.
  - Changes are breaking and must be coordinated with application logic.
*/
create type reaction_type as enum (
  'love',
  'like',
  'neutral',
  'heartbreak'
);

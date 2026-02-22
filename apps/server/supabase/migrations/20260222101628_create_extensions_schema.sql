/*
SCHEMA: extensions

ROLE IN THE SYSTEM:
  Dedicated schema for PostgreSQL extensions required by the application.

WHY THIS SCHEMA EXISTS:
  - PostgreSQL extensions are global database dependencies and must be created
    before any objects that rely on them.
  - Isolating extensions in a dedicated schema avoids polluting the public
    schema and makes extension usage explicit and auditable.
  - This schema is infrastructure-level and should contain extensions only.

CURRENT EXTENSIONS:
  - citext
    Used to enforce case-insensitive uniqueness for user-facing identifiers
    (e.g. usernames) while preserving original casing.

DESIGN INVARIANTS (DO NOT VIOLATE):
  - Application tables must assume required extensions already exist.
  - No application data, tables, or functions should be created in this schema.
  - Extensions should never be created implicitly or inline within table
    migrations.

MIGRATION ORDERING:
  - This migration MUST run before any migration that references extension-
    provided types or functions (e.g. CITEXT).
  - Reordering or removing this migration will cause downstream failures.

OPERATIONAL NOTES:
  - Extensions are database-scoped, this migration must run in every environment.
  - If additional extensions are required, they should be added here explicitly
    and documented with rationale.
*/
create schema if not exists extensions;

create extension if not exists citext
with schema extensions;

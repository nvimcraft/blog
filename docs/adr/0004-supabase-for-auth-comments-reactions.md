# ADR-0004: Supabase for Auth, Comments, Reactions

## Status

Accepted

## Context

We need authentication and a small set of interactive features (comments and
reactions) without building and operating a bespoke backend service.

The architecture expects the client to communicate with the backend directly
using Supabase’s public access pattern. When data is accessible from the browser,
authorization must be enforced at the database layer using Row Level Security
(RLS). Supabase states that RLS must be enabled on tables stored in an exposed
schema (by default, `public`), and that once enabled, data is not accessible via
the API until policies are created.

## Decision Drivers

- Minimize backend surface area and operational overhead (no custom API required
  for core interactions).
- Keep authorization enforceable at the data layer (“defense in depth”), not only
  in application code.
- Support the product rules:
  - Authenticated users can create/edit/delete only their own comments.
  - Authenticated users can add/edit/remove their own reactions.
  - Guests can view posts and counts (comments/reactions).

## Considered Options

1. **Custom backend (Worker API) + database**
   - Pros: full control over auth/session, endpoints, and data access patterns.
   - Cons: increases scope (API design, deployment, monitoring) for features that
     can be handled by RLS.

2. **Supabase for auth + data with RLS enforcement** (Chosen)
   - Pros: direct-from-client access is feasible when RLS policies enforce rules
     at the database layer.
   - Cons: requires careful policy design and consistent RLS enablement on
     exposed tables.

## Decision

Use Supabase for:

- Authentication (Supabase Auth)
- Comments storage + access control
- Reactions storage + access control

All authorization for comments/reactions is enforced with **Postgres RLS policies**.

## Consequences

### Positive

- Interactive features can be implemented with minimal “server” code.
- Authorization rules are centralized at the database layer via RLS policies.

### Negative / Risks

- RLS must be enabled on exposed tables (commonly `public`) and policies must be
  created; otherwise access will be blocked (or misconfigured policies could
  overexpose data). Supabase explicitly notes that RLS must be enabled on exposed
  tables and that no data will be accessible via the API until policies exist.
- Policy complexity becomes the primary security risk area; changes require
  review and testing discipline.

### Constraints / Boundaries

- The client uses the anon key access model; therefore **privileged operations
  must remain server-side** (e.g., anything requiring service role privileges or
  elevated trust).
- “Posts” are not managed in Supabase (content is local markdown); Supabase is
  limited to auth + comments + reactions.

## Links

- `docs/supabase.instructions.md` (implementation guidance and policy patterns)
- Related ADRs:
  - ADR-0003 (content: local markdown)
  - ADR-0002 (SPA on Cloudflare Workers)

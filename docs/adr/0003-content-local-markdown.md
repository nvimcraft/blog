# ADR-0003: Content Source = Local Markdown (Git as CMS)

## Status

Accepted

## Context

This blog is **owner-authored only**. We want:

- Minimal attack surface (no admin UI, no server-side content editing endpoints).
- Version control and reviewability for all content changes.
- A workflow that fits developer tooling (local editor + Git).

This decision is about **how posts are authored and stored**, not about
comments/reactions (handled separately via Supabase; see ADR-0004).

## Decision Drivers

- Security: avoid introducing a write-capable “content backend” or admin UI.
- Operational simplicity: no database migrations or CMS hosting for post content.
- Traceability: content changes should have a complete Git history.
- Portability: Markdown content should remain usable even if the app stack
  changes.

## Considered Options

1. **Hosted/headless CMS (e.g., Contentful/Sanity/etc.)**
   - Pros: admin UI, editorial workflow, structured content.
   - Cons: adds external dependency, auth surface area, and operational overhead.

2. **Store posts in a database (custom backend)**
   - Pros: full control and dynamic querying.
   - Cons: requires backend endpoints + auth + admin UI; increases attack surface.

3. **MDX content**
   - Pros: rich components and embedded interactivity.
   - Cons: increases complexity and runtime/tooling surface; not required for
     initial goals.

4. **Local Markdown tracked in Git** (Chosen)
   - Pros: simplest, lowest surface area, fully version-controlled.
   - Cons: requires build-time indexing and conventions for metadata.

## Decision

Write posts locally in **Markdown** files and publish by committing and pushing
to Git (repository is the “CMS”).

## Consequences

### Positive

- No admin UI is required for content creation/editing.
- Content changes are versioned, reviewable, and reversible via Git.

### Negative / Costs

- We must implement a **build-time content index step** to support:
  - “Top 3 latest posts” on home
  - `/posts` listing page
  - slug generation and metadata extraction (title/date/etc.)
- Publishing cadence is tied to repository changes (commit/push) rather than
  in-app publishing.

### Constraints / Boundaries

- Post creation/edit/delete does not occur inside the application.
- The application treats content as **read-only inputs** produced by the build pipeline.

## Links

- `docs/plan.json` (project overview and UI goals)
- `docs/client.instructions.md` (how content is loaded/rendered)
- `docs/deployment.cloudflare.md` (how build artifacts are deployed)
- ADR-0004 (Supabase for auth/comments/reactions)

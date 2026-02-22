# ADR-0001: Routing Library (TanStack Router)

## Status

Accepted

## Context

We are building a Vite + React + TypeScript single-page application (SPA) blog.
Routing requirements:

- File-based routing (routes represented by filesystem structure)
- Strong TypeScript support and typed navigation
- Route-based code splitting for performance (where possible)

TanStack Router supports file-based routing as a recommended approach and
documents that it improves organization, scalability, type-safety, and enables
automatic route code-splitting.

## Decision Drivers

- **File-based routing** should be the primary mental model (routes mirror
  URL structure).
- **Type-safe navigation**: links and navigation should be strongly typed and
  inferred.
- **Performance**: prefer route-based code splitting when configured. TanStack
  Router documents file-based routing + auto code splitting as a supported
  approach.
- **Maintainability**: avoid manually maintaining a large route config as the app grows.

## Options Considered

1. **TanStack Router (file-based routing)**
   - File-based routing is documented as preferred/recommended and provides
     benefits like organization, scalability, type-safety, and automatic
     code-splitting.

2. **React Router (library mode)**
   - Considered as a familiar alternative, but this ADR selects TanStack Router
     to standardize on file-based routing with TanStack’s generator/tooling.

## Decision

Use **TanStack Router** with **file-based routing**.

TanStack Router supports building route trees via file-based routing and treats
it as the preferred configuration method.

## Consequences

### Positive

- Routes are defined by filesystem structure, which TanStack documents as
  visually intuitive and maintainable.
- TypeScript type-safety and typesafe navigation are first-class features in
  TanStack Router.
- Route-based code splitting is supported, including “automatic code-splitting”
  for file-based routing when enabled/configured.

### Negative / Costs

- Requires integrating TanStack Router’s file-based routing tooling
  (generator/plugin) and handling the generated route tree file.
  - TanStack documents that file-based routing generates a route tree file
    (e.g., `routeTree.gen.ts`) that represents the route hierarchy.
- Requires adherence to TanStack Router’s file naming conventions to correctly
  express layouts, params, and nesting.

### Constraints / Boundaries

- This ADR decides **routing library and routing model**, not data loading
  strategy.
- File-based routing implies a “routes directory” and an auto-generated route
  tree artifact as part of the build/dev workflow.

## Links

- ADR-0002: SPA on Cloudflare Workers (deployment constraints)
- ADR-0003: Content source = local markdown (Git as CMS)
- ADR-0004: Supabase for auth/comments/reactions
- `docs/client.instructions.md` (routing usage conventions + page structure)

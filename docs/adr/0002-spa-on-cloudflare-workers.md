# ADR-0002: Host SPA on Cloudflare Workers (Static Assets + SPA fallback)

## Status

Accepted

## Context

We are deploying a Vite-built Single Page Application (SPA) and need:

- **Deep-link support** (e.g., `/posts/:slug`) where the edge returns the SPA
  shell (`index.html`)
- Edge-hosted static asset delivery and caching
- Optional ability to run Worker code for API endpoints (e.g., `/api/*`)
  alongside the SPA

Cloudflare Workers Static Assets deploys Worker code + static assets together and
can serve assets directly; by default, assets that match a request are served
without invoking Worker code, and the Worker runs only when there is no matching
asset.

## Decision Drivers

- SPA deep links must load the app shell (`index.html`) instead of returning 404s.
- Prefer asset-first serving for performance and reduced Worker invocations.
- Keep the “one-worker approach” possible (SPA + `/api/*`) when needed.

Cloudflare documents SPA mode for Workers Static Assets via
`assets.not_found_handling = "single-page-application"`, which serves
`index.html` when an incoming request does not match a file in the assets
directory.

## Considered Options

1. **Cloudflare Workers Static Assets (SPA mode)** (Chosen)
   - Supports serving static assets and SPA fallback via Wrangler configuration.

2. **Cloudflare Pages**
   - Considered as an alternative Cloudflare-hosting path for SPAs; Workers
     Static Assets is selected to keep Worker-level control available for hybrid
     SPA + API routing.

## Decision

Host the SPA using **Cloudflare Workers Static Assets** and enable SPA fallback
routing with:

- `assets.not_found_handling = "single-page-application"`

Cloudflare documents that this configuration serves `/index.html` with a 200 OK
for requests that do not match an uploaded asset.

## Consequences

### Positive

- Deep links (e.g., `/posts/my-slug`) resolve by serving `index.html` when no
  asset matches.
- Static assets are served efficiently, and by default assets are served without
  invoking Worker code (asset-first routing).
- Hybrid deployments remain possible: a Worker can still serve API responses and
  can defer to assets via an `ASSETS` binding (`env.ASSETS.fetch(request)`).

### Negative / Gotchas

- In SPA mode, Cloudflare documents “surprising but intentional” behavior for
  **navigation requests**:
  - Client-side `fetch("/api/...")` can still invoke the Worker and return JSON,
  - But browser navigation to `/api/...` may return `index.html` depending on SPA
    routing behavior.

### Constraints / Boundaries

- This ADR decides the **hosting target** and **SPA fallback behavior**.
- Route-level behavior for `/api/*` (if used) must account for the SPA-mode
  navigation behavior above.
- If we later need Worker-first routing for specific paths, Cloudflare provides
  `assets.run_worker_first` (boolean or array of patterns).

## Links

- `docs/deployment.cloudflare.md` (deployment behavior + SPA mode notes)
- `docs/server.instructions.md` (one-worker routing contract: `/api/*` vs assets)
- ADR-0001 (TanStack Router for client routing)
- ADR-0003 (content: local markdown + build-time indexing)
- ADR-0004 (Supabase for auth/comments/reactions)

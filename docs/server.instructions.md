# Server Instructions (One-Worker + Static Assets)

## Purpose

This repo uses **one Cloudflare Worker** to run a “hybrid” deployment:

- Serve **static assets** for the SPA (Vite build output).
- Handle **API endpoints** under `/api/*` (newsletter via Resend; future
  server-only actions).

Cloudflare Workers Static Assets deploys Worker code + static assets as a single
unit, and allows the Worker to serve assets via an `ASSETS` binding.

---

## Scope (What belongs in the Worker)

**In scope**

- `/api/newsletter/*` endpoints (Resend).
- Any _future_ “server-only” actions that must not run in the client.

**Out of scope**

- Auth/comments/reactions: prefer client → Supabase direct with RLS enforcement
  (see “Supabase Boundary”). _(Project decision from plan;
  not a platform requirement.)_

---

## Repo layout

- Worker app: `apps/server/`
- Supabase local config: `apps/supabase/`
- Recommended Worker entry file:
  - `apps/server/src/worker.ts` (or `apps/server/src/index.ts`)
  - Wrangler `main` should point at this entry.

---

## Routing Contract (Critical)

### Contract (authoritative)

1. Requests to `/api/*` **must** be handled by Worker code and return JSON.
2. All non-`/api/*` routes **must** be served as static assets (SPA).
3. SPA deep links (e.g. `/posts/my-slug`) **must** return `index.html`.

Cloudflare’s recommended pattern is to branch on `/api/` and otherwise return
`env.ASSETS.fetch(request)` to serve static assets.

### Reference implementation (minimal)

```ts
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url)

    // 1) API routes
    if (url.pathname.startsWith('/api/')) {
      return handleApi(request, env)
    }

    // 2) Everything else -> static assets (SPA)
    return env.ASSETS.fetch(request)
  },
}
```

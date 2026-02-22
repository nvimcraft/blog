# Deployment (Cloudflare Workers + Static Assets, SPA mode)

## Purpose

Deploy the blog as a **single Cloudflare Worker** that:

- serves the SPA build output as **Static Assets**, and
- (optionally) exposes JSON endpoints under `/api/*` from Worker code.

Cloudflare Workers Static Assets deploys Worker code + asset bundle together and
provides an `ASSETS` binding that can serve files via
`env.ASSETS.fetch(request)`.

> Related: `docs/server.instructions.md` defines the routing contract for
> `/api/*` vs assets.

## Deployment Model (What Cloudflare does by default)

### Default routing precedence (important)

With Static Assets enabled:

- If a request **matches a file** in the assets directory, Cloudflare serves it
  **without invoking** your Worker code.
- If **no asset matches** and you have a Worker script (`main`), the Worker is
  invoked.

This default behavior is good for SPAs because most requests are static and
should not bill Worker invocations.

## SPA Deep Links (Required)

### Why

Deep links like `/posts/my-slug` do not correspond to physical files, but should
still load the SPA shell (`index.html`) so the client router can render the route.

### Wrangler setting

Enable SPA fallback routing:

- `assets.not_found_handling = "single-page-application"`

When enabled, if a request does **not** match an uploaded asset, Cloudflare
serves `/index.html` with `200 OK`.

### Minimal Wrangler example (conceptual)

```toml
# wrangler.toml (or equivalent JSONC)
[assets]
directory = "./dist"
not_found_handling = "single-page-application"
```

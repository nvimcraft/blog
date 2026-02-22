# Client Instructions (Vite + React/TS + TanStack Router)

## Purpose

This document defines the **client app contract**:

- Vite + React + TypeScript SPA
- TanStack Router with **file-based routing**
- Markdown content rendering (not MDX)
- Build-time support for “Top 3 latest posts” and post listings (see ADR-0003)

---

## Scope / Non-goals

**In scope**

- Client routing conventions (TanStack Router)
- Client content rules (Markdown posts)
- Generated file hygiene rules required for stable builds/dev UX

**Out of scope**

- Cloudflare deployment configuration (see `docs/deployment.cloudflare.md`)
- Worker/API routing details (see `docs/server.instructions.md`)
- Supabase schema and RLS policy SQL (see `docs/supabase.instructions.md`)

---

## Routing (TanStack Router, file-based)

### Contract (authoritative)

- Routing is **file-based**: the filesystem under the routes directory represents
  the URL hierarchy.
- TanStack’s Vite integration generates a route tree file
  (default: `./src/routeTree.gen.ts`).
- Enable route code-splitting via `autoCodeSplitting: true` in the router plugin
  config.

### Vite plugin setup (required)

Install the plugin and register it in `vite.config.ts`.

**Important ordering rule:** TanStack Router’s plugin must be registered
**before** `@vitejs/plugin-react`. TanStack documents this explicitly.

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    // Must come before '@vitejs/plugin-react'
    tanstackRouter({
      target: 'react',
      autoCodeSplitting: true,
    }),
    react(),
  ],
})
```

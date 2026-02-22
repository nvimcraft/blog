# Supabase Instructions (Auth + Comments + Reactions)

## Purpose

Supabase is the backend for:

- Authentication (Supabase Auth)
- Comments
- Reactions

The client is expected to talk to Supabase directly using the public anon key, so
**Row Level Security (RLS) is mandatory** for any exposed tables. Supabase
explicitly recommends enabling RLS on tables in exposed schemas
(commonly `public`).

## Scope (What Supabase is responsible for)

**In scope**

- User identity (Auth)
- Data storage for comments and reactions
- Authorization enforcement at the database layer (RLS policies)

**Out of scope**

- Blog post content (posts are local markdown in the repo)
- “Owner creates posts” rules (enforced by Git workflow, not Supabase)

---

## Security Model (Authoritative)

### 1) Enable RLS on every exposed table

Supabase’s docs state RLS should be enabled on tables stored in an exposed schema
(by default `public`).

Enable RLS (example):

```sql
alter table public.<table_name> enable row level security;
```

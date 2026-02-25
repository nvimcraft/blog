/*
TABLE: public.newsletter_subscriptions

ROLE IN THE SYSTEM:
  Stores newsletter subscriber emails with verification tokens.
  Supports double opt-in flow (verification required before active).

CORE INVARIANTS (DO NOT VIOLATE):
  - One subscription per email (unique constraint on email).
  - Tokens are single-use and must be consumed within 24 hours.
  - Verified subscribers have confirmed ownership of the email.

VERIFICATION FLOW (Authoritative):
  1. User submits email → pending subscription created with token
  2. Confirmation email sent with token link
  3. User clicks link → token validated + email re-entry required
  4. On match → subscription marked as verified

SECURITY & PRIVACY:
  - Email is PII - do not expose via API without consideration.
  - Tokens are secrets - treat as single-use, expire after 24h.
*/
create table public.newsletter_subscriptions (
  id uuid primary key default gen_random_uuid(),
  email citext not null unique
    check (
      email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
  token uuid not null unique default gen_random_uuid(),
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  consumed_at timestamptz
);

-- Index for verification lookup
create index if not exists newsletter_token_idx
  on public.newsletter_subscriptions (token) 
  where verified = false;

-- Index for email lookup
create index if not exists newsletter_email_idx
  on public.newsletter_subscriptions (email);

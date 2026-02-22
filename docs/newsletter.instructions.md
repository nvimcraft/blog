# Newsletter Instructions (Resend)

## Purpose

Provide a newsletter subscription flow that does **not** require an account:

- Collect an email address
- Verify ownership via a confirmation link
- Send transactional emails (verification + newsletters) via Resend from a Cloudflare Worker

Cloudflare documents a Workers tutorial for sending transactional emails using
Resend, including domain setup and storing API keys securely with secrets.

---

## Scope / Non-goals

**In scope**

- Subscription + verification flow (double opt-in style)
- Email delivery through Resend, triggered by Worker endpoints

**Out of scope**

- Full newsletter campaign management UI
- User accounts / profiles for subscribers
- Bulk list management tooling (can be added later)

---

## Subscription Flow (Authoritative Contract)

### Requirements

- No account required.
- Email required.
- Verification required via confirmation link.
- On confirmation link click: require **email re-entry** and perform
  **email match confirmation** before marking subscription verified.

> This “re-enter email” step is a project choice to reduce accidental or
> malicious confirmations (extra friction by design).

### Planned endpoints (Worker)

These endpoints align with your “one-worker routing contract” and are intended
to be implemented under `/api/newsletter/*`:

- `POST /api/newsletter/subscribe`
- `GET /api/newsletter/confirm?token=...`
- Optional: `POST /api/newsletter/unsubscribe`

(Endpoint list comes from your existing server documentation; this newsletter doc
describes behavior, not implementation details.)

### Token semantics (implementation guidance)

**Not specified by source docs** — below is guidance for maintainers (treat as
project convention):

- Use a single-use token that maps to a pending subscription request.
- Store the token server-side (or in a database) with:
  - email
  - created timestamp
  - verified flag
  - consumed timestamp (optional)
- Only mark verified when:
  1. token is valid and unexpired
  2. email re-entry matches the stored email

---

## Delivery (Resend via Cloudflare Workers)

### Delivery contract

- Verification emails and newsletter emails are sent via Resend from a Cloudflare
  Worker endpoint.

Cloudflare provides an official tutorial: **Send Emails With Resend** (Workers).
It covers creating a Worker, adding/verifying a domain in Resend, and sending
mail through the Resend SDK.  
Resend also provides its own “send with Cloudflare Workers” guide and example approach.

### Secrets (required)

Store API keys and sensitive values as Cloudflare Worker **secrets**
(encrypted bindings).
Cloudflare’s secrets documentation states secrets are accessed through the `env`
parameter in the Worker fetch handler (and can also be accessed via
`cloudflare:workers` env import).

Minimum secret for newsletter delivery:

- `RESEND_API_KEY` (Resend API key)

### Local development note (secrets)

Cloudflare recommends using `.dev.vars` or `.env` (dotenv format) for local
development secrets and explicitly warns not to commit those files to git.

---

## Operational Notes (Cloudflare SPA mode interaction)

If you are hosting the SPA with Workers Static Assets in SPA mode, Cloudflare
documents behavior where:

- client-side `fetch("/api/...")` still invokes Worker code as expected,
- but browser navigation to an `/api/...` path may be served HTML (`index.html`)
  in SPA mode.

**Maintainer rule**

- Treat newsletter endpoints as API-only: test with `fetch()` or `curl`, not by
  browser navigation.

---

## Maintainer Checklist

- [ ] Worker can send emails via Resend (see Cloudflare tutorial).
- [ ] `RESEND_API_KEY` stored as a Worker secret, accessed via `env`.
- [ ] Subscribe flow requires email + sends confirmation email.
- [ ] Confirm flow requires token + email re-entry + email match confirmation.
- [ ] Newsletter sending is triggered from Worker endpoint(s), not from the
      client bundle (keeps API keys private).

---

## References

- [Cloudflare Workers tutorial: Send Emails With Resend](https://developers.cloudflare.com/workers/tutorials/send-emails-with-resend/)
- [Resend guide: Send emails with Cloudflare Workers](https://resend.com/docs/send-with-cloudflare-workers)
- [Cloudflare Workers secrets documentation](https://developers.cloudflare.com/workers/configuration/secrets/)

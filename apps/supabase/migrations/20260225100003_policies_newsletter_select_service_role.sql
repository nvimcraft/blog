/*
POLICY: newsletter_subscriptions_select_service_role
PURPOSE:
  - Service role only can SELECT (email privacy)
  - No public read access to subscriber emails
*/
drop policy if exists "newsletter_subscriptions_select_public" on public.newsletter_subscriptions;
drop policy if exists "newsletter_subscriptions_select_service_role" on public.newsletter_subscriptions;

create policy "newsletter_subscriptions_select_service_role"
  on public.newsletter_subscriptions for select
  to service_role
  using (true);

set local lock_timeout = '10s'
;
alter table public.newsletter_subscriptions enable row level security;

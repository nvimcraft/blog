/*
POLICY: newsletter_subscriptions_update_blocked

PURPOSE:
  - Block all direct UPDATE access
  - Updates must go through RPC functions (verify_subscription, unsubscribe)
*/
drop policy if exists "newsletter_subscriptions_update_blocked" on public.newsletter_subscriptions;

create policy "newsletter_subscriptions_update_blocked"
  on public.newsletter_subscriptions for update
  to anon, authenticated
  using (false)
  with check (false);

/*
POLICY: newsletter_subscriptions_delete_service_role

PURPOSE:
  - DELETE only for service_role
  - Regular users cannot delete subscriptions (soft-delete via unsubscribe RPC instead)
*/
drop policy if exists "newsletter_subscriptions_delete_service_role" on public.newsletter_subscriptions;
drop policy if exists "newsletter_subscriptions_delete_blocked" on public.newsletter_subscriptions;

create policy "newsletter_subscriptions_delete_blocked"
  on public.newsletter_subscriptions for delete
  to anon, authenticated
  using (false);

create policy "newsletter_subscriptions_delete_service_role"
  on public.newsletter_subscriptions for delete
  to service_role
  using (true);

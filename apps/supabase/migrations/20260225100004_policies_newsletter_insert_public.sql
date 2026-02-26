/*
POLICY: newsletter_subscriptions_insert_public

PURPOSE:
  - Anyone can subscribe (insert) - requiresAccount = false per plan
  - verified=false is enforced by column default
  - Prevents pre-verified subscriptions
*/
drop policy if exists "newsletter_subscriptions_insert_public" on public.newsletter_subscriptions;

create policy "newsletter_subscriptions_insert_public"
  on public.newsletter_subscriptions for insert
  to anon, authenticated
  with check (verified = false);

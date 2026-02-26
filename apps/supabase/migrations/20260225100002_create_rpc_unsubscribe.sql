/*
RPC: public.unsubscribe

PURPOSE:
  Allow users to unsubscribe from newsletter via token-based link.
  Implements soft-delete by marking subscription as unsubscribed.

SECURITY:
  - Uses security definer to bypass RLS
  - Sets search_path to prevent attacks
  - Token-based (no email exposed in URL)
  - Single-use (token can only unsubscribe once)

INPUT:
  - p_token: UUID token from unsubscribe link in email

ERROR CODES:
  - P0001: Invalid token
  - P0002: Already unsubscribed
*/
create or replace function public.unsubscribe(p_token uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_subscription record;
  v_result boolean := false;
begin
  -- Find the subscription by token
  select id, email, verified, unsubscribed_at
  into v_subscription
  from public.newsletter_subscriptions
  where token = p_token;

  -- Check if subscription exists
  if v_subscription.id is null then
    raise exception 'Invalid token' using errcode = 'P0001';
  end if;

  -- Check if already unsubscribed
  if v_subscription.unsubscribed_at is not null then
    raise exception 'Already unsubscribed' using errcode = 'P0002';
  end if;

  -- Mark as unsubscribed (soft delete)
  update public.newsletter_subscriptions
  set 
    verified = false,
    unsubscribed_at = now()
  where id = v_subscription.id;

  v_result := true;

  return v_result;
end;
$$
;

-- Grant execute permission to anon and authenticated roles
grant execute
on function public.unsubscribe(uuid)
to anon, authenticated
;

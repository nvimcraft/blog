/*
RPC: public.verify_subscription

PURPOSE:
  Verify a newsletter subscription via double opt-in flow.
  Called when user clicks confirmation link and re-enters their email.

SECURITY:
  - Uses security definer to bypass RLS
  - Sets search_path to prevent attacks
  - Token expires after 24 hours
  - Requires email re-entry for verification (prevents accidental/automated clicks)

INPUT:
  - p_token: UUID token from confirmation email
  - p_email: User's email (re-entered for verification)

ERROR CODES:
  - P0001: Invalid token
  - P0002: Already verified
  - P0003: Token expired
  - P0004: Token already used
  - P0005: Email mismatch
*/
create or replace function public.verify_subscription(p_token uuid, p_email text)
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
  select id, email, verified, created_at, consumed_at
  into v_subscription
  from public.newsletter_subscriptions
  where token = p_token;

  -- Check if subscription exists
  if v_subscription.id is null then
    raise exception 'Invalid token' using errcode = 'P0001';
  end if;

  -- Check if already verified
  if v_subscription.verified then
    raise exception 'Already verified' using errcode = 'P0002';
  end if;

  -- Check if token is expired (24 hours)
  if v_subscription.created_at < now() - interval '24 hours' then
    raise exception 'Token expired' using errcode = 'P0003';
  end if;

  -- Check if already consumed
  if v_subscription.consumed_at is not null then
    raise exception 'Token already used' using errcode = 'P0004';
  end if;

  -- Verify email re-entry matches (case-insensitive)
  if lower(v_subscription.email) <> lower(p_email) then
    raise exception 'Email mismatch' using errcode = 'P0005';
  end if;

  -- Mark as verified
  update public.newsletter_subscriptions
  set 
    verified = true,
    verified_at = now(),
    consumed_at = now()
  where id = v_subscription.id;

  v_result := true;

  return v_result;
end;
$$
;

-- Grant execute permission to anon and authenticated roles
grant execute
on function public.verify_subscription(uuid, text)
to anon, authenticated
;

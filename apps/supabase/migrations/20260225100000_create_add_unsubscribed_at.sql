/*
SCHEMA: public.newsletter_subscriptions

Add unsubscribed_at column for soft-delete unsubscribe functionality.

This allows users to unsubscribe via token without requiring account login.
The column tracks when a user voluntarily unsubscribed.
*/
set local lock_timeout = '10s'
;
alter table public.newsletter_subscriptions 
add column if not exists unsubscribed_at timestamptz;

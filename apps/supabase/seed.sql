-- Creates non-login demo users only.
delete from public.reactions
;
delete from public.comments
;
delete from auth.identities
;
delete from auth.users
;

with
    seeded_users as (
        select
            unnest(
                array[
                    '11111111-1111-1111-1111-111111111111'::uuid,
                    '22222222-2222-2222-2222-222222222222'::uuid
                ]
            ) as id,
            unnest(array['user1@example.com', 'user2@example.com']) as email,
            unnest(array['demo-user-1', 'demo-user-2']) as username
    )
    insert into auth.users(
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at
    )
select
    '00000000-0000-0000-0000-000000000000',
    u.id,
    'authenticated',
    'authenticated',
    u.email,
    -- random/unknown password per user (not intended for login)
    crypt(gen_random_uuid()::text, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('username', u.username),
    now(),
    now()
from seeded_users u
;

-- Fail if the trigger didn't create profiles.
select
    1 / (
        select count(*)
        from public.profiles
        where id = '11111111-1111-1111-1111-111111111111'::uuid
    )
;

select
    1 / (
        select count(*)
        from public.profiles
        where id = '22222222-2222-2222-2222-222222222222'::uuid
    )
;

insert into public.comments (post_id, user_id, content)
values
  ('hello-world', '11111111-1111-1111-1111-111111111111', 'Seeded comment from demo-user-1'),
  ('hello-world', '22222222-2222-2222-2222-222222222222', 'Seeded comment from demo-user-2'),
  ('about',       '11111111-1111-1111-1111-111111111111', 'Seeded comment on about page');

insert into public.reactions (post_id, user_id, type)
values
  ('hello-world', '11111111-1111-1111-1111-111111111111', 'like'),
  ('hello-world', '22222222-2222-2222-2222-222222222222', 'love'),
  ('about',       '11111111-1111-1111-1111-111111111111', 'neutral');

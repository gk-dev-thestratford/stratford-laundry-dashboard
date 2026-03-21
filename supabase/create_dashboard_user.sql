-- ============================================
-- Create Dashboard User: georgi@thestratford.com
-- Run this in Supabase SQL Editor
-- ============================================

DO $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Step 1: Create the auth user
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, confirmation_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'georgi@thestratford.com',
    crypt('polka', gen_salt('bf')),
    NOW(),
    NOW(), NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Georgi"}',
    FALSE, ''
  ) RETURNING id INTO new_user_id;

  -- Step 2: Create the identity record (required for login)
  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id,
    new_user_id,
    jsonb_build_object('sub', new_user_id::text, 'email', 'georgi@thestratford.com'),
    'email',
    NOW(), NOW(), NOW()
  );

  -- Step 3: Add to dashboard_users table
  INSERT INTO dashboard_users (id, email, name, role, is_active)
  VALUES (new_user_id, 'georgi@thestratford.com', 'Georgi', 'admin', TRUE);

  RAISE NOTICE 'Dashboard user created with ID: %', new_user_id;
END $$;

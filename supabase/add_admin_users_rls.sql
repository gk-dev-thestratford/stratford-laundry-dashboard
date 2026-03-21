-- Allow authenticated dashboard users to manage admin_users (tablet admins)
-- Run this in Supabase SQL Editor

CREATE POLICY "auth_insert_admin_users" ON admin_users
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_update_admin_users" ON admin_users
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "auth_delete_admin_users" ON admin_users
  FOR DELETE USING (auth.role() = 'authenticated');

-- Fix: deleting a tablet user from the web User Management page failed with an
-- FK violation — every status-log row they ever wrote references
-- admin_users(id) with the default NO ACTION. APPLIED 2026-06-12 via MCP
-- (approved by Georgi). History must outlive the account: changed_by_name
-- (text) keeps the display name in ticket timelines, so the FK now nulls out
-- on user deletion. No existing data touched.
ALTER TABLE order_status_log DROP CONSTRAINT order_status_log_changed_by_fkey;
ALTER TABLE order_status_log ADD CONSTRAINT order_status_log_changed_by_fkey
  FOREIGN KEY (changed_by) REFERENCES admin_users(id) ON DELETE SET NULL;

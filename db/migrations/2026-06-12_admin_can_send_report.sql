-- Per-admin permission: who can see the tablet's Today's Report panel and send
-- the daily report. APPLIED 2026-06-12 via MCP. Default true preserves current
-- behaviour; toggled from the web dashboard's User Management page.
ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS can_send_report BOOLEAN NOT NULL DEFAULT true;

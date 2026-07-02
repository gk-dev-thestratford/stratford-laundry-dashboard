-- Per-admin gate for APPROVING submitted tickets on the tablet.
-- Mirrors can_reject_orders / can_send_report. Defaults to TRUE so every
-- existing tablet user keeps the ability to approve; switch it OFF on the web
-- User Management page to hide the Approve button for a specific user.
-- Additive, nullable-safe (IF NOT EXISTS) — safe to re-run.
ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS can_approve_orders BOOLEAN NOT NULL DEFAULT true;

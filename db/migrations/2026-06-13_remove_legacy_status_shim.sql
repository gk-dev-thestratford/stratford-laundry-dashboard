-- Remove the temporary legacy-status compatibility shim. APPLIED 2026-06-13 via MCP.
-- The old tablet APK is no longer in use — the new APK (v1.2.0+12 and later)
-- writes the five-stage status names directly. Confirmed by Georgi 2026-06-13:
-- single tablet device, synced before installing the new build.
-- Reverses the shim added in 2026-06-12_five_stage_status_model.sql.
DROP TRIGGER IF EXISTS orders_legacy_status_shim ON orders;
DROP TRIGGER IF EXISTS order_status_log_legacy_shim ON order_status_log;
DROP FUNCTION IF EXISTS normalize_legacy_order_status();
DROP FUNCTION IF EXISTS normalize_legacy_status_log();

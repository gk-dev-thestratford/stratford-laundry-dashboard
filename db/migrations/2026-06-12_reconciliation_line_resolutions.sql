-- ============================================================================
-- Reconciliation persistence — per-line resolutions snapshot + missing D140 columns
-- Generated 2026-06-12. Run in Supabase dashboard → SQL Editor (MCP is read-only).
-- Both statements are additive (nullable columns) — no data is touched.
-- ============================================================================

-- 1) Per-line work snapshot (resolutions, challenge flags, per-line notes).
--    Saved by the dashboard on "Save", restored when the same invoice number is
--    uploaded again. The app falls back gracefully if this column is missing,
--    but nothing persists until it exists.
ALTER TABLE public.reconciliations
  ADD COLUMN IF NOT EXISTS line_resolutions jsonb;

-- 2) D140 guest-margin analysis columns. The dashboard's "Save D140 Analysis"
--    button has been writing to these columns, but they were never created —
--    every D140 save so far has silently failed (console error only).
ALTER TABLE public.reconciliations
  ADD COLUMN IF NOT EXISTS d140_summary jsonb,
  ADD COLUMN IF NOT EXISTS d140_total_revenue numeric,
  ADD COLUMN IF NOT EXISTS d140_total_cost numeric,
  ADD COLUMN IF NOT EXISTS d140_total_margin numeric,
  ADD COLUMN IF NOT EXISTS d140_margin_pct numeric;

-- ---- Verify after running ---------------------------------------------------
-- SELECT column_name FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='reconciliations'
--     AND column_name IN ('line_resolutions','d140_summary','d140_total_revenue',
--                         'd140_total_cost','d140_total_margin','d140_margin_pct');
-- Expect 6 rows.

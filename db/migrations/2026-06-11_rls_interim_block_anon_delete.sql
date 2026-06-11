-- ============================================================================
-- INTERIM RLS hardening — block the catastrophic operations without breaking the tablet
-- Generated 2026-06-11. Safe to run NOW if the tablet only CREATES orders via anon.
-- ============================================================================
--
-- This is the low-risk middle ground for the wide-open-RLS issue (audit C1):
--   * Anon can still SELECT (read) and INSERT (create) — so the tablet keeps working.
--   * Anon can NO LONGER DELETE or UPDATE — those are the operations that let an
--     anonymous internet user wipe or tamper with the whole dataset. DELETE/UPDATE
--     are done from the dashboard by signed-in staff, who keep working via the
--     `authenticated` policies below.
--
-- If, after running this, order STATUS changes from the tablet stop working, the tablet
-- does UPDATE via anon too — in that case re-add `auth`+`anon` UPDATE temporarily and plan
-- the move to an authenticated tablet account (the proper fix in the full lockdown file).
-- ============================================================================

-- ---- orders: remove anon DELETE + UPDATE; keep anon SELECT + INSERT --------
DROP POLICY IF EXISTS anon_delete_orders ON public.orders;
DROP POLICY IF EXISTS anon_update_orders ON public.orders;
CREATE POLICY auth_update_orders ON public.orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_orders ON public.orders FOR DELETE TO authenticated USING (true);

-- ---- order_items -----------------------------------------------------------
DROP POLICY IF EXISTS anon_delete_order_items ON public.order_items;
DROP POLICY IF EXISTS anon_update_order_items ON public.order_items;
CREATE POLICY auth_update_order_items ON public.order_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_order_items ON public.order_items FOR DELETE TO authenticated USING (true);

-- ---- order_status_log ------------------------------------------------------
DROP POLICY IF EXISTS anon_delete_status_log ON public.order_status_log;
DROP POLICY IF EXISTS anon_update_status_log ON public.order_status_log;
CREATE POLICY auth_update_status_log ON public.order_status_log FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_status_log ON public.order_status_log FOR DELETE TO authenticated USING (true);

-- Note: this keeps anon INSERT (tablet order creation) + anon SELECT untouched.
-- The full role-based lockdown (also restricting INSERT/SELECT) is in
-- 2026-06-11_rls_lockdown_REVIEW_BEFORE_RUNNING.sql — do that once the tablet
-- moves to an authenticated account.

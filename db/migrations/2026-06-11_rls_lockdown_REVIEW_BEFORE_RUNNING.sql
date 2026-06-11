-- ============================================================================
-- CRITICAL SECURITY FIX — Row Level Security lockdown
-- Generated 2026-06-11.  DO NOT RUN BLINDLY — read the warning first.
-- ============================================================================
--
-- PROBLEM (audit finding C1):
--   The public `anon` role currently has INSERT / UPDATE / DELETE on orders,
--   order_items, order_status_log, linen_ledger, reconciliations with USING/
--   WITH CHECK = true.  The anon key is embedded in the shipped web bundle, so
--   ANY anonymous internet user can read, modify, or DELETE the entire dataset
--   (2,500+ orders).  Login on the dashboard is currently cosmetic.
--
-- BEFORE YOU RUN THIS — confirm how the TABLET / Flutter app (master branch)
-- talks to Supabase:
--   * If the tablet signs in (authenticated session): this migration is safe —
--     it scopes all WRITES to `authenticated` and is the correct target state.
--   * If the tablet writes using the ANON key (no login on a shared device):
--     running the write-restriction below WILL BREAK order creation on the
--     tablet.  In that case do NOT run it as-is.  Instead move the tablet onto
--     an authenticated service account (or an Edge Function with a server-side
--     secret), THEN run this.  Restricting by role is the only robust fix;
--     leaving anon writes open is not production-safe.
--
-- SELECT (read) is intentionally LEFT OPEN to anon below, on the assumption the
-- tablet reads catalogue/orders via anon.  If the tablet authenticates for reads
-- too, also drop the anon SELECT policies and recreate them TO authenticated.
-- ============================================================================

-- ---- orders ----------------------------------------------------------------
DROP POLICY IF EXISTS anon_insert_orders ON public.orders;
DROP POLICY IF EXISTS anon_update_orders ON public.orders;
DROP POLICY IF EXISTS anon_delete_orders ON public.orders;
CREATE POLICY auth_insert_orders ON public.orders FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY auth_update_orders ON public.orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_orders ON public.orders FOR DELETE TO authenticated USING (true);

-- ---- order_items -----------------------------------------------------------
DROP POLICY IF EXISTS anon_insert_items ON public.order_items;
DROP POLICY IF EXISTS anon_update_order_items ON public.order_items;
DROP POLICY IF EXISTS anon_delete_order_items ON public.order_items;
CREATE POLICY auth_insert_order_items ON public.order_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY auth_update_order_items ON public.order_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_order_items ON public.order_items FOR DELETE TO authenticated USING (true);

-- ---- order_status_log ------------------------------------------------------
DROP POLICY IF EXISTS anon_insert_log ON public.order_status_log;
DROP POLICY IF EXISTS anon_update_status_log ON public.order_status_log;
DROP POLICY IF EXISTS anon_delete_status_log ON public.order_status_log;
CREATE POLICY auth_insert_status_log ON public.order_status_log FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY auth_update_status_log ON public.order_status_log FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_status_log ON public.order_status_log FOR DELETE TO authenticated USING (true);

-- ---- linen_ledger ----------------------------------------------------------
DROP POLICY IF EXISTS anon_insert_linen_ledger ON public.linen_ledger;
CREATE POLICY auth_insert_linen_ledger ON public.linen_ledger FOR INSERT TO authenticated WITH CHECK (true);

-- ---- reconciliations (currently ALL true to public) ------------------------
DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.reconciliations;
CREATE POLICY auth_read_reconciliations   ON public.reconciliations FOR SELECT TO authenticated USING (true);
CREATE POLICY auth_insert_reconciliations ON public.reconciliations FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY auth_update_reconciliations ON public.reconciliations FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY auth_delete_reconciliations ON public.reconciliations FOR DELETE TO authenticated USING (true);

-- ---- Verify after running --------------------------------------------------
-- SELECT tablename, policyname, cmd, roles FROM pg_policies
--   WHERE schemaname='public'
--     AND tablename IN ('orders','order_items','order_status_log','linen_ledger','reconciliations')
--   ORDER BY tablename, cmd;
-- Expect: SELECT may remain {public}; INSERT/UPDATE/DELETE should be {authenticated}.

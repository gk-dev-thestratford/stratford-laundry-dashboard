-- ============================================================================
-- Reconciliation Phase 1: explained lines, credit notes, order resolutions,
-- action history, invoice-note drafts, sign-off, Goldstar contacts.
-- Generated 2026-11-08. Run in Supabase dashboard → SQL Editor (one go).
-- Approved design: specs/2026-11-07-reconciliation-phase1/ (current-vs-new.html)
--
-- Everything here is ADDITIVE: new tables, new nullable columns, and one CHECK
-- constraint widened to allow the new 'service_wash' tag. No data is changed
-- or removed. All new tables: signed-in users only (no anonymous access).
-- ============================================================================

-- 1) Line notes: service wash tag + who-pays details --------------------------
ALTER TABLE public.reconciliation_line_notes
  DROP CONSTRAINT IF EXISTS reconciliation_line_notes_charge_type_check;
ALTER TABLE public.reconciliation_line_notes
  ADD CONSTRAINT reconciliation_line_notes_charge_type_check
  CHECK (charge_type IN ('note', 'room_missing', 'group', 'service_wash', 'house', 'other'));
ALTER TABLE public.reconciliation_line_notes
  ADD COLUMN IF NOT EXISTS recharge_status text
    CHECK (recharge_status IN ('recharged', 'not_yet', 'not_chargeable')),
  ADD COLUMN IF NOT EXISTS folio_ref  text,
  ADD COLUMN IF NOT EXISTS weight_kg  numeric;

-- 2) Orders: "Not charged by Goldstar" (counts as £0 cost in reports) ----------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS not_charged_at     timestamptz,
  ADD COLUMN IF NOT EXISTS not_charged_by     text,
  ADD COLUMN IF NOT EXISTS not_charged_reason text;

-- 3) Resolutions for orders that are in our system but not on an invoice -------
--    expect_next  = expect on next invoice (carried forward and ticked off later)
--    not_charged  = Goldstar didn't bill it (orders.not_charged_at also set)
--    write_off / credit_query = as named
CREATE TABLE IF NOT EXISTS public.reconciliation_order_resolutions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text NOT NULL CHECK (invoice_number <> ''),
  order_id       uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  resolution     text NOT NULL CHECK (resolution IN ('expect_next', 'not_charged', 'write_off', 'credit_query')),
  note           text,
  found_on_invoice text,            -- set when an expected order turns up on a later invoice
  created_by     text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (invoice_number, order_id)
);
CREATE INDEX IF NOT EXISTS reconciliation_order_resolutions_open_idx
  ON public.reconciliation_order_resolutions (resolution) WHERE found_on_invoice IS NULL;

-- 4) Credit note requests to Goldstar -----------------------------------------
CREATE TABLE IF NOT EXISTS public.reconciliation_credit_requests (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference        text NOT NULL UNIQUE,                  -- CR-<invoice>-<n>
  invoice_number   text NOT NULL CHECK (invoice_number <> ''),
  status           text NOT NULL DEFAULT 'requested'
                   CHECK (status IN ('requested', 'received', 'closed', 'cancelled')),
  lines            jsonb NOT NULL DEFAULT '[]'::jsonb,   -- [{line_key|order_id, date, ticket, guest, description, invoice_net, reason, reason_text, credit_net}]
  net              numeric NOT NULL DEFAULT 0,
  vat              numeric NOT NULL DEFAULT 0,
  total            numeric NOT NULL DEFAULT 0,
  to_emails        text,
  cc_emails        text,
  message          text,
  requested_by     text,
  requested_at     timestamptz NOT NULL DEFAULT now(),
  credit_note_no   text,
  received_amount  numeric,
  received_by      text,
  received_at      timestamptz,
  closed_at        timestamptz,
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reconciliation_credit_requests_open_idx
  ON public.reconciliation_credit_requests (status) WHERE status IN ('requested', 'received');

-- 5) Action history (who did what, when) --------------------------------------
CREATE TABLE IF NOT EXISTS public.reconciliation_actions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text,
  line_key       text,
  order_id       uuid,
  action         text NOT NULL,
  detail         text,
  actor          text,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reconciliation_actions_invoice_idx ON public.reconciliation_actions (invoice_number, line_key);

-- 6) Invoice-note drafts (autosave, survives re-upload without Save) -----------
CREATE TABLE IF NOT EXISTS public.reconciliation_drafts (
  invoice_number text PRIMARY KEY CHECK (invoice_number <> ''),
  note           text,
  updated_by     text,
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- 7) Sign-off on saved reconciliations ----------------------------------------
ALTER TABLE public.reconciliations
  ADD COLUMN IF NOT EXISTS approved_by text,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz;

-- 8) Goldstar contacts + reconciliation settings ------------------------------
CREATE TABLE IF NOT EXISTS public.supplier_contacts (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email      text NOT NULL,
  role       text NOT NULL DEFAULT 'to' CHECK (role IN ('to', 'cc')),
  added_by   text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (email)
);
CREATE TABLE IF NOT EXISTS public.reconciliation_settings (
  key        text PRIMARY KEY,
  value      text,
  updated_by text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ---- Row Level Security: signed-in users only --------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['reconciliation_order_resolutions','reconciliation_credit_requests',
                           'reconciliation_actions','reconciliation_drafts','supplier_contacts',
                           'reconciliation_settings']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_auth_all', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t || '_auth_all', t);
    EXECUTE format('REVOKE ALL ON public.%I FROM anon', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
  END LOOP;
END $$;

-- ---- Seed Goldstar contacts from the daily-report list (no duplicates) -------
INSERT INTO public.supplier_contacts (email, role, added_by)
VALUES ('info@goldstardrycleaning.co.uk', 'to', 'migration 2026-11-08'),
       ('set1000@hotmail.com', 'cc', 'migration 2026-11-08')
ON CONFLICT (email) DO NOTHING;
INSERT INTO public.reconciliation_settings (key, value, updated_by)
VALUES ('credit_chase_days', '30', 'migration 2026-11-08'),
       ('credit_signature', 'The Stratford — Laundry Team', 'migration 2026-11-08')
ON CONFLICT (key) DO NOTHING;

-- ---- Verify after running -----------------------------------------------------
-- SELECT tablename, policyname, roles FROM pg_policies
--  WHERE tablename IN ('reconciliation_order_resolutions','reconciliation_credit_requests',
--   'reconciliation_actions','reconciliation_drafts','supplier_contacts','reconciliation_settings');
-- Expect 6 rows, all {authenticated}.

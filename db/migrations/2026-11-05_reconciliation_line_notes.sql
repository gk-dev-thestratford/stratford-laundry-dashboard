-- ============================================================================
-- Reconciliation line notes ("Charge to") + group folios
-- Generated 2026-11-05. Run in Supabase dashboard → SQL Editor.
-- Additive only: two NEW tables. No existing table, column or row is touched.
-- ============================================================================
--
-- Why: Goldstar's guest invoices print some lines with NO room number. Those are
-- either group charges (posted to a group master folio in Opera), house use, or
-- Goldstar simply forgot the room. The reconciliation needs to tag each such line
-- (and optionally any other line) so the accounts team can cross-check revenue
-- vs charges per group, and see the tags in the breakdown, Excel and PDF.
--
-- Line identity: (invoice_number, line_key) where line_key =
--   "<date>|<ticket>|<net>|<occurrence>" — occurrence counts identical
--   date+ticket+net lines in invoice order. Deliberately excludes guest name and
--   description so a parser change can't orphan notes.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.reconciliation_line_notes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  text NOT NULL CHECK (invoice_number <> ''),
  line_key        text NOT NULL CHECK (line_key <> ''),
  -- Copy of the invoice line, so a note can be re-attached / shown if the line
  -- no longer appears (corrected or re-issued invoice).
  line_date       text,
  ticket          text,
  guest_label     text,
  description     text,
  net             numeric,
  -- note         = plain note on a line
  -- room_missing = Goldstar left the room off; room_override holds the right room
  -- group        = group charge (group_name)
  -- house        = house use
  -- other        = anything else (group_name holds the account / label)
  charge_type     text NOT NULL DEFAULT 'note'
                  CHECK (charge_type IN ('note', 'room_missing', 'group', 'house', 'other')),
  room_override   text,
  group_name      text,
  note            text,
  -- Order the user explicitly picked for this line ("who could it be"). This is
  -- the authoritative link — order notes only get a human-readable copy on Save.
  order_id        uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  mirrored_to_order_at timestamptz,
  updated_by      text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (invoice_number, line_key)
);

CREATE INDEX IF NOT EXISTS reconciliation_line_notes_group_idx
  ON public.reconciliation_line_notes (group_name) WHERE group_name IS NOT NULL;

-- Per-invoice group details: the Opera group master folio room (D140 revenue is
-- matched on it automatically) plus a manual revenue / folio reference fallback.
CREATE TABLE IF NOT EXISTS public.reconciliation_group_folios (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  text NOT NULL CHECK (invoice_number <> ''),
  group_name      text NOT NULL CHECK (group_name <> ''),
  master_room     text,
  revenue_posted  numeric,
  folio_ref       text,
  note            text,
  updated_by      text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (invoice_number, group_name)
);

-- ---- Row Level Security: signed-in dashboard users only (no anon access) ----
ALTER TABLE public.reconciliation_line_notes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reconciliation_group_folios ENABLE ROW LEVEL SECURITY;

CREATE POLICY rln_select ON public.reconciliation_line_notes FOR SELECT TO authenticated USING (true);
CREATE POLICY rln_insert ON public.reconciliation_line_notes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY rln_update ON public.reconciliation_line_notes FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY rln_delete ON public.reconciliation_line_notes FOR DELETE TO authenticated USING (true);

CREATE POLICY rgf_select ON public.reconciliation_group_folios FOR SELECT TO authenticated USING (true);
CREATE POLICY rgf_insert ON public.reconciliation_group_folios FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY rgf_update ON public.reconciliation_group_folios FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY rgf_delete ON public.reconciliation_group_folios FOR DELETE TO authenticated USING (true);

REVOKE ALL ON public.reconciliation_line_notes   FROM anon;
REVOKE ALL ON public.reconciliation_group_folios FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reconciliation_line_notes   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reconciliation_group_folios TO authenticated;

-- ---- Verify after running ---------------------------------------------------
-- SELECT tablename, policyname, roles, cmd FROM pg_policies
--   WHERE tablename IN ('reconciliation_line_notes', 'reconciliation_group_folios')
--   ORDER BY tablename, cmd;
-- Expect 8 rows, every one with roles = {authenticated}.

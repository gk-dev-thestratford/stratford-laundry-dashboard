-- Migration: Add linen_ledger table for pool-based napkin tracking
-- Napkins are tracked as a running balance (OUT/IN) rather than per-ticket

CREATE TABLE IF NOT EXISTS linen_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL DEFAULT 'Linen Napkins',
  direction TEXT NOT NULL CHECK (direction IN ('out', 'in')),
  quantity INTEGER NOT NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  department_id UUID REFERENCES departments(id),
  note TEXT,
  recorded_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_linen_ledger_direction ON linen_ledger(direction);
CREATE INDEX idx_linen_ledger_created ON linen_ledger(created_at DESC);

ALTER TABLE linen_ledger ENABLE ROW LEVEL SECURITY;

-- Anon (tablet app) policies
CREATE POLICY "anon_insert_linen_ledger" ON linen_ledger FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_read_linen_ledger" ON linen_ledger FOR SELECT USING (true);

-- Authenticated (web dashboard) full access
CREATE POLICY "auth_all_linen_ledger" ON linen_ledger FOR ALL USING (auth.role() = 'authenticated');

-- Also add the missing UPDATE policy on order_status_log (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'order_status_log' AND policyname = 'anon_update_status_log'
  ) THEN
    CREATE POLICY "anon_update_status_log" ON order_status_log FOR UPDATE USING (true);
  END IF;
END $$;

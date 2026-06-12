-- Editable recipient list for the daily laundry report. APPLIED 2026-06-12 via MCP.
-- Managed from the web dashboard's Configuration page; the daily-report edge
-- function reads it when the caller doesn't supply recipients (e.g. the
-- tablet's payload-less invoke). Seeded with the previously hardcoded list.
CREATE TABLE IF NOT EXISTS report_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  added_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE report_recipients ENABLE ROW LEVEL SECURITY;

-- Dashboard users (authenticated) manage the list. No anon access — the tablet
-- never reads this table directly; the edge function uses the service role.
CREATE POLICY "authenticated manage report recipients" ON report_recipients
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO report_recipients (email, added_by) VALUES
  ('kunov.georgi@gmail.com', 'migration seed'),
  ('georgi@thestratford.com', 'migration seed'),
  ('set1000@hotmail.com', 'migration seed')
ON CONFLICT (email) DO NOTHING;

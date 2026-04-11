-- Migration: Add item_department_access table + RLS policies
-- This junction table was created via the web Catalogue page but lacked
-- RLS policies, preventing the tablet (anon role) from reading it.

-- Create the table if it doesn't exist yet (idempotent)
CREATE TABLE IF NOT EXISTS item_department_access (
  item_id UUID NOT NULL REFERENCES item_catalogue(id) ON DELETE CASCADE,
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, department_id)
);

-- Enable RLS
ALTER TABLE item_department_access ENABLE ROW LEVEL SECURITY;

-- Anon (tablet app) can read department-item mappings
CREATE POLICY "anon_read_item_dept_access" ON item_department_access
  FOR SELECT USING (true);

-- Authenticated (web dashboard) has full access
CREATE POLICY "auth_all_item_dept_access" ON item_department_access
  FOR ALL USING (auth.role() = 'authenticated');

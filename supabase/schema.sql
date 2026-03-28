-- The Stratford Hotel — Laundry Management System
-- Supabase PostgreSQL Schema
-- Run this in Supabase SQL Editor to create all tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Departments ──
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  can_submit_uniforms BOOLEAN NOT NULL DEFAULT TRUE,
  has_linen_items BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ── Item Catalogue ──
CREATE TABLE item_catalogue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('uniform', 'hsk_linen', 'fnb_linen')),
  price DECIMAL(10,2),
  department_id UUID REFERENCES departments(id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- ── Admin Users (tablet app) ──
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ── Orders ──
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  docket_number TEXT NOT NULL,
  order_type TEXT NOT NULL CHECK (order_type IN ('uniform', 'hsk_linen', 'fnb_linen', 'guest_laundry')),
  department_id UUID REFERENCES departments(id),
  staff_name TEXT,
  email TEXT,
  room_number TEXT,
  guest_name TEXT,
  bag_count INTEGER,
  notes TEXT,
  parent_order_id UUID REFERENCES orders(id),
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'approved', 'rejected', 'collected', 'in_processing', 'received', 'completed', 'picked_up', 'expired')),
  total_price DECIMAL(10,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at TIMESTAMPTZ
);

-- ── Order Items ──
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  item_id UUID REFERENCES item_catalogue(id),
  item_name TEXT NOT NULL,
  quantity_sent INTEGER NOT NULL,
  quantity_received INTEGER,
  price_at_time DECIMAL(10,2)
);

-- ── Order Status Log ──
CREATE TABLE order_status_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  changed_by UUID REFERENCES admin_users(id),
  changed_by_name TEXT,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Dashboard Users (web) ──
CREATE TABLE dashboard_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  department_id UUID REFERENCES departments(id),
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'viewer')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ── Indexes ──
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_department ON orders(department_id);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_docket ON orders(docket_number);
CREATE INDEX idx_orders_parent ON orders(parent_order_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_status_log_order ON order_status_log(order_id);

-- ── Linen Napkin Pool Ledger ──
-- Tracks napkin quantities as a running balance (OUT = sent to laundry, IN = received back).
-- Napkins are pool-tracked rather than per-ticket because the laundry company rounds return quantities.
CREATE TABLE linen_ledger (
  id TEXT PRIMARY KEY,
  item_name TEXT NOT NULL DEFAULT 'Linen Napkins',
  direction TEXT NOT NULL CHECK (direction IN ('out', 'in')),
  quantity INTEGER NOT NULL,
  order_id TEXT REFERENCES orders(id) ON DELETE SET NULL,
  department_id TEXT REFERENCES departments(id),
  note TEXT,
  recorded_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_linen_ledger_direction ON linen_ledger(direction);
CREATE INDEX idx_linen_ledger_created ON linen_ledger(created_at DESC);

-- ── Row Level Security ──
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_catalogue ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE linen_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_users ENABLE ROW LEVEL SECURITY;

-- Anon (tablet app) can read reference data
CREATE POLICY "anon_read_departments" ON departments FOR SELECT USING (true);
CREATE POLICY "anon_read_catalogue" ON item_catalogue FOR SELECT USING (true);
CREATE POLICY "anon_read_admins" ON admin_users FOR SELECT USING (true);

-- Anon can insert orders and items (staff submission)
CREATE POLICY "anon_insert_orders" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_insert_items" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_insert_log" ON order_status_log FOR INSERT WITH CHECK (true);

-- Anon can read and update orders (for admin panel on tablet)
CREATE POLICY "anon_read_orders" ON orders FOR SELECT USING (true);
CREATE POLICY "anon_update_orders" ON orders FOR UPDATE USING (true);
CREATE POLICY "anon_read_order_items" ON order_items FOR SELECT USING (true);
CREATE POLICY "anon_update_order_items" ON order_items FOR UPDATE USING (true);
CREATE POLICY "anon_read_status_log" ON order_status_log FOR SELECT USING (true);
CREATE POLICY "anon_update_status_log" ON order_status_log FOR UPDATE USING (true);

-- Anon can insert and read linen ledger entries (tablet app)
CREATE POLICY "anon_insert_linen_ledger" ON linen_ledger FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_read_linen_ledger" ON linen_ledger FOR SELECT USING (true);

-- Authenticated dashboard users: full access
CREATE POLICY "auth_all_orders" ON orders FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_all_items" ON order_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_all_log" ON order_status_log FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_all_departments" ON departments FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_all_catalogue" ON item_catalogue FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_all_linen_ledger" ON linen_ledger FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "auth_read_dashboard_users" ON dashboard_users FOR SELECT USING (auth.uid() = id);

-- ── Seed Data: Departments ──
INSERT INTO departments (code, name, can_submit_uniforms, has_linen_items) VALUES
  ('KEF', 'Kitchen E20 Front', TRUE, FALSE),
  ('KIT', 'Main Kitchen', TRUE, FALSE),
  ('LNG', 'Lounge', TRUE, FALSE),
  ('EVT', 'Events', TRUE, FALSE),
  ('HSK', 'Housekeeping', TRUE, TRUE),
  ('SMK', 'Sales & Marketing', TRUE, FALSE),
  ('HRS', 'Human Resources', TRUE, FALSE),
  ('MNT', 'Maintenance', TRUE, FALSE),
  ('ACC', 'Accounts', TRUE, FALSE),
  ('RSV', 'Reservation', TRUE, FALSE),
  ('SEC', 'Security', TRUE, FALSE),
  ('LFT', 'Loft Team', TRUE, FALSE),
  ('GMT', 'General Management', TRUE, FALSE);

-- ── Seed Data: Uniform Items (all prices excl. VAT) ──
INSERT INTO item_catalogue (code, name, category, price, sort_order) VALUES
  ('UNI-001', 'Shirt', 'uniform', 1.10, 1),
  ('UNI-002', 'Blouse', 'uniform', 2.20, 2),
  ('UNI-003', 'Trouser/Jeans', 'uniform', 2.75, 3),
  ('UNI-004', 'Dress', 'uniform', 5.50, 4),
  ('UNI-005', 'Jacket/Blazer', 'uniform', 2.75, 5),
  ('UNI-006', 'Apron', 'uniform', 0.99, 6),
  ('UNI-009', 'Chef Jacket', 'uniform', 1.34, 7),
  ('UNI-010', 'Chef Trouser', 'uniform', 1.48, 8),
  ('UNI-011', '2 Piece Suit', 'uniform', 5.50, 9),
  ('UNI-012', 'Hoody/Jumper', 'uniform', 3.00, 10),
  ('UNI-013', 'Coat', 'uniform', 4.95, 11),
  ('UNI-014', 'Pullover', 'uniform', 2.75, 12),
  ('UNI-015', 'T-Shirt/Polo Shirt', 'uniform', 1.74, 13);

-- ── Seed Data: Linen Items (all prices excl. VAT) ──
INSERT INTO item_catalogue (code, name, category, price, sort_order)
SELECT items.code, items.name, 'fnb_linen', items.price, items.sort_order FROM (VALUES
  ('FNB-002', 'Table Cloth', 3.25::DECIMAL, 1),
  ('FNB-003', 'Linen Napkins', 0.22::DECIMAL, 2)
) AS items(code, name, price, sort_order);

INSERT INTO item_catalogue (code, name, category, price, department_id, sort_order)
SELECT 'HSK-004', 'Bathrobes', 'hsk_linen', 2.99, d.id, 1
FROM departments d WHERE d.code = 'HSK';

-- ── Trigger: Auto-update updated_at ──
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

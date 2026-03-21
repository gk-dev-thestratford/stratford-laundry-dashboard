-- Migration: Update items and departments to match actual Stratford data
-- All prices are EXCLUDING VAT
-- Run this in Supabase SQL Editor

BEGIN;

-- ══════════════════════════════════════════════
-- 1. DEPARTMENTS
-- ══════════════════════════════════════════════

-- Rename existing departments
UPDATE departments SET name = 'Main Kitchen' WHERE code = 'KIT';
UPDATE departments SET name = 'Loft Team', can_submit_uniforms = TRUE WHERE code = 'LFT';

-- Deactivate departments no longer in use
UPDATE departments SET is_active = false WHERE code IN ('FNB', 'FOH', 'SPA', 'MGT', 'GST');

-- Add new departments
INSERT INTO departments (code, name, can_submit_uniforms, has_linen_items) VALUES
  ('KEF', 'Kitchen E20 Front', TRUE, FALSE),
  ('LNG', 'Lounge', TRUE, FALSE),
  ('EVT', 'Events', TRUE, FALSE),
  ('SMK', 'Sales & Marketing', TRUE, FALSE),
  ('HRS', 'Human Resources', TRUE, FALSE),
  ('ACC', 'Accounts', TRUE, FALSE),
  ('RSV', 'Reservation', TRUE, FALSE),
  ('GMT', 'General Management', TRUE, FALSE)
ON CONFLICT (code) DO NOTHING;

-- ══════════════════════════════════════════════
-- 2. ITEMS — Update existing uniform items
-- ══════════════════════════════════════════════

UPDATE item_catalogue SET price = 1.10 WHERE code = 'UNI-001'; -- Shirt
UPDATE item_catalogue SET price = 2.20 WHERE code = 'UNI-002'; -- Blouse
UPDATE item_catalogue SET name = 'Trouser/Jeans', price = 2.75 WHERE code = 'UNI-003';
UPDATE item_catalogue SET price = 5.50 WHERE code = 'UNI-004'; -- Dress
UPDATE item_catalogue SET price = 2.75 WHERE code = 'UNI-005'; -- Jacket/Blazer
UPDATE item_catalogue SET price = 0.99 WHERE code = 'UNI-006'; -- Apron
UPDATE item_catalogue SET price = 1.34 WHERE code = 'UNI-009'; -- Chef Jacket
UPDATE item_catalogue SET name = 'Chef Trouser', price = 1.48 WHERE code = 'UNI-010';

-- Deactivate uniform items no longer in list (Tie, Waistcoat)
UPDATE item_catalogue SET is_active = false WHERE code IN ('UNI-007', 'UNI-008');

-- ══════════════════════════════════════════════
-- 3. ITEMS — Add new uniform items
-- ══════════════════════════════════════════════

INSERT INTO item_catalogue (code, name, category, price, sort_order) VALUES
  ('UNI-011', '2 Piece Suit', 'uniform', 5.50, 11),
  ('UNI-012', 'Hoody/Jumper', 'uniform', 3.00, 12),
  ('UNI-013', 'Coat', 'uniform', 4.95, 13),
  ('UNI-014', 'Pullover', 'uniform', 2.75, 14),
  ('UNI-015', 'T-Shirt/Polo Shirt', 'uniform', 1.74, 15)
ON CONFLICT (code) DO NOTHING;

-- ══════════════════════════════════════════════
-- 4. ITEMS — Update linen items with prices
-- ══════════════════════════════════════════════

-- Note: Linen Napkins price £0.215 rounded to £0.22 (DB uses 2 decimal places)
UPDATE item_catalogue SET name = 'Linen Napkins', price = 0.22 WHERE code = 'FNB-003';
UPDATE item_catalogue SET name = 'Table Cloth', price = 3.25 WHERE code = 'FNB-002';
UPDATE item_catalogue SET name = 'Bathrobes', price = 2.99 WHERE code = 'HSK-004';

-- Deactivate linen items not in the current list
UPDATE item_catalogue SET is_active = false WHERE code IN (
  'FNB-001',
  'HSK-001', 'HSK-002', 'HSK-003',
  'HSK-005', 'HSK-006', 'HSK-007', 'HSK-008', 'HSK-009'
);

COMMIT;

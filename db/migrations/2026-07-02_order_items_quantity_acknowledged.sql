-- Laundry company's own acknowledged count per item (from their yellow
-- receipt), used to flag receiving discrepancies on the tablet:
--   • Dispute  — sent != acknowledged (staff vs laundry count mismatch)
--   • Short    — (acknowledged ?? sent) - received > 0 (still owed back)
--   • Over     — received > sent (extra items came back)
-- Nullable; only set when staff record a discrepancy. Additive, safe to re-run.
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS quantity_acknowledged INTEGER;

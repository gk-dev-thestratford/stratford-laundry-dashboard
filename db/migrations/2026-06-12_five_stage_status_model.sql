-- Five-stage status model: submitted -> approved -> sent -> received -> collected
-- (+ rejected, expired as auxiliary). Approved by Georgi 2026-06-12. APPLIED 2026-06-12 via MCP.
--
-- Why: staff found the old names confusing — old 'collected' meant "collected by the
-- laundry company" but staff read it as "owner collected items". New model:
--   submitted     staff recorded the ticket
--   approved      HSK admin acknowledged items present, prepared for sending
--   sent          laundry company collected for washing   (was: collected + in_processing)
--   received      back from the laundry company           (was: received + completed)
--   collected     owner (staff member) picked up items    (was: picked_up)
--
-- Result on apply: orders rewritten — sent 41, received 656, collected 1781 (submitted 3,
-- rejected 81 untouched). order_status_log normalized (all pre-migration 'collected' logs
-- meant "collected by laundry company" = new 'sent').

BEGIN;

-- 1. Drop constraints/indexes that reference old status names
ALTER TABLE orders DROP CONSTRAINT orders_status_check;
DROP INDEX orders_docket_number_active_unique;

-- 2. Rewrite order statuses (single atomic CASE — order-safe for the collected->sent vs picked_up->collected collision)
UPDATE orders SET status = CASE status
  WHEN 'collected'     THEN 'sent'
  WHEN 'in_processing' THEN 'sent'
  WHEN 'completed'     THEN 'received'
  WHEN 'picked_up'     THEN 'collected'
  ELSE status END
WHERE status IN ('collected', 'in_processing', 'completed', 'picked_up');

-- 3. Normalize historical status-log rows
UPDATE order_status_log SET status = CASE status
  WHEN 'collected'     THEN 'sent'
  WHEN 'in_processing' THEN 'sent'
  WHEN 'completed'     THEN 'received'
  WHEN 'picked_up'     THEN 'collected'
  ELSE status END
WHERE status IN ('collected', 'in_processing', 'completed', 'picked_up');

-- 4. Strict new constraint (legacy writes are normalized by the shim trigger BEFORE the check runs)
ALTER TABLE orders ADD CONSTRAINT orders_status_check
  CHECK (status IN ('submitted', 'approved', 'rejected', 'sent', 'received', 'collected', 'expired'));

-- 5. Recreate docket uniqueness among ACTIVE orders, same semantics as before:
--    old predicate excluded picked_up/completed/rejected -> new excludes collected/received/rejected
--    (+ expired, which the old predicate missed — expired orders are finished too).
CREATE UNIQUE INDEX orders_docket_number_active_unique ON orders (docket_number)
  WHERE status NOT IN ('collected', 'received', 'rejected', 'expired');

-- 6. Compatibility shim: old tablet APK still writes legacy status names.
--    BEFORE triggers run before CHECK constraints, so legacy values are mapped transparently.
--    'collected' written over an 'approved'/'submitted' order = old bulk-collect = new 'sent'.
--    REMOVE THIS TRIGGER once the new APK is confirmed installed on the tablet:
--      DROP TRIGGER orders_legacy_status_shim ON orders;
--      DROP TRIGGER order_status_log_legacy_shim ON order_status_log;
--      DROP FUNCTION normalize_legacy_order_status();
--      DROP FUNCTION normalize_legacy_status_log();
CREATE OR REPLACE FUNCTION normalize_legacy_order_status() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'in_processing' THEN NEW.status := 'sent';
  ELSIF NEW.status = 'completed' THEN NEW.status := 'received';
  ELSIF NEW.status = 'picked_up' THEN NEW.status := 'collected';
  ELSIF NEW.status = 'collected' AND TG_OP = 'UPDATE' AND OLD.status IN ('approved', 'submitted') THEN
    NEW.status := 'sent';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS orders_legacy_status_shim ON orders;
CREATE TRIGGER orders_legacy_status_shim
  BEFORE INSERT OR UPDATE OF status ON orders
  FOR EACH ROW EXECUTE FUNCTION normalize_legacy_order_status();

-- 7. Same shim for status-log inserts (keeps the email webhook + daily report queries
--    on new names). For an ambiguous 'collected' log, the order row (already shimmed)
--    being 'sent' identifies it as a legacy bulk-collect log.
CREATE OR REPLACE FUNCTION normalize_legacy_status_log() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'in_processing' THEN NEW.status := 'sent';
  ELSIF NEW.status = 'completed' THEN NEW.status := 'received';
  ELSIF NEW.status = 'picked_up' THEN NEW.status := 'collected';
  ELSIF NEW.status = 'collected'
    AND EXISTS (SELECT 1 FROM orders o WHERE o.id = NEW.order_id AND o.status = 'sent') THEN
    NEW.status := 'sent';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS order_status_log_legacy_shim ON order_status_log;
CREATE TRIGGER order_status_log_legacy_shim
  BEFORE INSERT ON order_status_log
  FOR EACH ROW EXECUTE FUNCTION normalize_legacy_status_log();

COMMIT;

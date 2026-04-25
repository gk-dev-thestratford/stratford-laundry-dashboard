-- Clean up existing duplicate orders before applying the unique-docket index.
--
-- HOW TO USE:
--   1. Run "STEP 1" below to LIST the duplicates. Review the output.
--   2. Decide if the auto-rule (keep the oldest active row per docket) matches
--      what you want. If it does, run "STEP 2" to mark the duplicates as
--      rejected. If you want to keep a specific row instead, edit the WHERE
--      clause in STEP 2 by hand.
--   3. Re-run STEP 1 — it should now return zero rows.
--   4. Apply 2026-04-25_orders_unique_docket.sql to enforce uniqueness going
--      forward.
--
-- NOTHING in this file modifies data until you uncomment STEP 2.

-- ── STEP 1: list all duplicates (read-only) ──
-- Shows every docket_number with >1 non-rejected order, oldest first.
with dupes as (
  select docket_number
  from public.orders
  where status <> 'rejected'
  group by docket_number
  having count(*) > 1
)
select
  o.docket_number,
  o.id,
  o.status,
  o.order_type,
  o.staff_name,
  o.guest_name,
  o.created_at,
  row_number() over (
    partition by o.docket_number
    order by o.created_at asc
  ) as rank_oldest_first
from public.orders o
join dupes d using (docket_number)
where o.status <> 'rejected'
order by o.docket_number, o.created_at asc;

-- ── STEP 2: mark all-but-the-oldest as rejected (DESTRUCTIVE — uncomment to run) ──
--
-- Auto-rule: keep the OLDEST non-rejected order per docket_number, mark every
-- newer duplicate as 'rejected' with a reason that points to the kept row.
-- The data isn't deleted — just hidden from normal views — so you can recover
-- if needed by flipping status back.
--
-- with dupes as (
--   select docket_number
--   from public.orders
--   where status <> 'rejected'
--   group by docket_number
--   having count(*) > 1
-- ),
-- ranked as (
--   select
--     o.id,
--     o.docket_number,
--     row_number() over (
--       partition by o.docket_number
--       order by o.created_at asc
--     ) as rn,
--     first_value(o.id) over (
--       partition by o.docket_number
--       order by o.created_at asc
--     ) as keeper_id
--   from public.orders o
--   join dupes d using (docket_number)
--   where o.status <> 'rejected'
-- )
-- update public.orders o
-- set
--   status = 'rejected',
--   updated_at = now(),
--   notes = coalesce(o.notes, '') ||
--           case when o.notes is null or o.notes = '' then '' else E'\n' end ||
--           '[Auto-deduped] Duplicate of order ' || ranked.keeper_id
-- from ranked
-- where o.id = ranked.id
--   and ranked.rn > 1;
--
-- -- Insert a status_log entry for the audit trail
-- insert into public.order_status_log (order_id, status, changed_by_name, reason, created_at)
-- select o.id, 'rejected', 'System (deduplication)',
--        'Auto-rejected as duplicate of an earlier order with the same docket number',
--        now()
-- from public.orders o
-- where o.status = 'rejected'
--   and o.notes like '[Auto-deduped]%'
--   and not exists (
--     select 1 from public.order_status_log l
--     where l.order_id = o.id
--       and l.status = 'rejected'
--       and l.changed_by_name = 'System (deduplication)'
--   );

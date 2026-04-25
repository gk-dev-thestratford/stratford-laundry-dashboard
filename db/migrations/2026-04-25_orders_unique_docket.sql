-- Server-side duplicate guard for orders.docket_number
--
-- Background: the tablet app's submit button could be tapped multiple times
-- during a slow sync, creating multiple local orders with the same docket
-- number but different UUIDs. All copies sync up to Supabase, leaving the
-- web dashboard showing the same docket multiple times.
--
-- Client-side fixes (submit-button guard + 60s recency check) prevent new
-- duplicates. This index is the *server-side* safety net so that even if a
-- buggy client tries again, Postgres refuses the second insert.
--
-- It's a PARTIAL unique index excluding rejected orders, because a docket
-- can legitimately be re-used after the original was rejected.
--
-- Apply via Supabase SQL Editor.

-- IMPORTANT: clean up existing duplicates BEFORE applying the index, or the
-- creation will fail. Run db/migrations/2026-04-25_dedupe_orders.sql first.

create unique index if not exists orders_docket_number_active_unique
  on public.orders (docket_number)
  where status <> 'rejected';

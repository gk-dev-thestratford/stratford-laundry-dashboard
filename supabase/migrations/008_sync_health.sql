-- Cross-device sync-health + bounded discrepancy history.
-- Lets a dashboard/website flag a tablet that has unsynced work or has gone
-- quiet, and keeps a short event log (NOT the whole cache) for a period.
--
-- The Flutter app connects with the ANON key only (no end-user auth; admin is a
-- local PIN), so anon must be able to upsert/select. Tighten if you add auth.
--
-- Apply:  supabase db push   (or run this SQL in the dashboard SQL editor),
--         against project uhpiwiaadzwgmnusjinv.
-- The tablet's heartbeat (SyncService._sendHeartbeat) writes device_sync_status
-- automatically once these tables exist; until then it no-ops harmlessly.

create table if not exists public.device_sync_status (
  device_id          text primary key,
  device_label       text,
  last_sync_at       timestamptz,
  pending_count      integer not null default 0,
  local_order_count  integer not null default 0,
  app_version        text,
  updated_at         timestamptz not null default now()
);

create table if not exists public.sync_events (
  id          uuid primary key default gen_random_uuid(),
  device_id   text,
  event       text not null,   -- e.g. 'push_failed', 'orphan_delete_blocked'
  detail      text,
  created_at  timestamptz not null default now()
);
create index if not exists idx_sync_events_created_at
  on public.sync_events (created_at desc);

alter table public.device_sync_status enable row level security;
alter table public.sync_events       enable row level security;

-- Match the app's existing anon-key model. Replace with authenticated-only
-- policies if/when end-user auth is introduced.
drop policy if exists device_sync_status_anon_all on public.device_sync_status;
create policy device_sync_status_anon_all on public.device_sync_status
  for all to anon using (true) with check (true);

drop policy if exists sync_events_anon_rw on public.sync_events;
create policy sync_events_anon_rw on public.sync_events
  for all to anon using (true) with check (true);

-- Bounded history: prune sync_events older than 90 days. If pg_cron is enabled:
--   select cron.schedule('prune_sync_events', '0 3 * * *',
--     $$delete from public.sync_events where created_at < now() - interval '90 days'$$);

-- Suggested dashboard "discrepancy" query (devices needing attention):
--   select device_id, device_label, last_sync_at, pending_count, local_order_count
--   from public.device_sync_status
--   where pending_count > 0 or last_sync_at < now() - interval '30 minutes'
--   order by pending_count desc, last_sync_at asc;

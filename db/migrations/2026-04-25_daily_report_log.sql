-- Daily Report Log
--
-- Records each manual send of the daily laundry report.
-- Powers the "Last sent" indicator in the dashboard activity panel
-- and provides an audit trail for what was reported on which day.
--
-- Apply via Supabase SQL Editor.

create table if not exists public.daily_report_log (
  id uuid primary key default gen_random_uuid(),
  sent_at timestamptz not null default now(),
  sent_by_user_id uuid references auth.users (id) on delete set null,
  sent_by_name text,

  -- Snapshot counts of what the report contained
  collected_count integer not null default 0,
  received_count integer not null default 0,
  outstanding_qty integer not null default 0,
  napkin_returns_count integer not null default 0,
  napkin_returns_qty integer not null default 0,

  -- Audit pointers to the actual rows included
  collected_order_ids uuid[] not null default '{}',
  received_order_ids uuid[] not null default '{}',
  napkin_ledger_ids uuid[] not null default '{}',

  -- Recipients + per-recipient send result
  email_recipients text[] not null default '{}',
  send_result jsonb,

  notes text
);

create index if not exists daily_report_log_sent_at_idx
  on public.daily_report_log (sent_at desc);

alter table public.daily_report_log enable row level security;

-- Authenticated dashboard users can read all entries
drop policy if exists "Authenticated read daily_report_log" on public.daily_report_log;
create policy "Authenticated read daily_report_log"
  on public.daily_report_log
  for select
  using (auth.role() = 'authenticated');

-- Authenticated dashboard users can insert (the manual Send flow writes here)
drop policy if exists "Authenticated insert daily_report_log" on public.daily_report_log;
create policy "Authenticated insert daily_report_log"
  on public.daily_report_log
  for insert
  with check (auth.role() = 'authenticated');

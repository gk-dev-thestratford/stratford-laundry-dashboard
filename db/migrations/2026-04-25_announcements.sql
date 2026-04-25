-- Announcements / scheduled message cards
--
-- Lets dashboard admins push a message that appears as a banner on the
-- tablet's admin dashboard + order-type screen for a configurable
-- date/time window, then disappears automatically.
--
-- Apply via Supabase SQL Editor.

create table if not exists public.announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  severity     text not null default 'info'
                 check (severity in ('info', 'warning', 'critical')),
  is_active    boolean not null default true,
  created_by   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint announcements_window_valid check (ends_at > starts_at)
);

create index if not exists announcements_window_idx
  on public.announcements (starts_at, ends_at) where is_active;

alter table public.announcements enable row level security;

-- Authenticated dashboard users can read all (needed for the management UI to
-- show upcoming/active/expired tabs).
drop policy if exists "Authenticated read announcements" on public.announcements;
create policy "Authenticated read announcements"
  on public.announcements
  for select
  using (auth.role() = 'authenticated');

-- Authenticated dashboard users can create/update/delete announcements.
drop policy if exists "Authenticated insert announcements" on public.announcements;
create policy "Authenticated insert announcements"
  on public.announcements
  for insert
  with check (auth.role() = 'authenticated');

drop policy if exists "Authenticated update announcements" on public.announcements;
create policy "Authenticated update announcements"
  on public.announcements
  for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "Authenticated delete announcements" on public.announcements;
create policy "Authenticated delete announcements"
  on public.announcements
  for delete
  using (auth.role() = 'authenticated');

-- The tablet uses the anon key — let it READ active announcements only.
-- (No insert/update from the tablet — the dashboard owns the message.)
drop policy if exists "Anon read active announcements" on public.announcements;
create policy "Anon read active announcements"
  on public.announcements
  for select
  to anon
  using (is_active = true);

-- Auto-bump updated_at on update
create or replace function public.tg_announcements_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tg_announcements_updated_at on public.announcements;
create trigger tg_announcements_updated_at
  before update on public.announcements
  for each row execute function public.tg_announcements_set_updated_at();

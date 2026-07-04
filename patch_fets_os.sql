-- ============================================================
-- FETS OS — CENTRE ROLLOUT patch
-- Paste this whole file into Supabase Dashboard → SQL Editor → Run.
-- Adds the centres + centre_rollout tables that power the
-- Centre Rollout view: every approved Standard automatically
-- becomes a launch-checklist item for each new centre.
-- Safe to run more than once.
-- ============================================================

create table if not exists centres (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  status text not null default 'planned' check (status in ('live','launching','planned')),
  sort_order int not null default 100,
  launched_at date,
  created_at timestamptz not null default now()
);

create table if not exists centre_rollout (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references centres(id) on delete cascade,
  actionable_id uuid not null references actionables(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started','in_progress','done','na')),
  note text,
  updated_by uuid references staff(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, actionable_id)
);

-- ---------- RLS (same permissive posture as the rest of the app) ----------
alter table centres enable row level security;
alter table centre_rollout enable row level security;

drop policy if exists anon_all_centres on centres;
drop policy if exists anon_all_centre_rollout on centre_rollout;
create policy anon_all_centres on centres for all using (true) with check (true);
create policy anon_all_centre_rollout on centre_rollout for all using (true) with check (true);

-- ---------- seed: the two live centres + Centre #3 ----------
insert into centres (name, status, sort_order) values
  ('Cochin Centre', 'live', 1),
  ('Calicut Centre', 'live', 2),
  ('Centre #3', 'launching', 3)
on conflict (name) do nothing;

-- Done! Refresh actionables.html — the Centre Rollout view lights up.

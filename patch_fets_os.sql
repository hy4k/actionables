-- ============================================================
-- FETS OS patch — Centre Rollout · Launch Playbook · Compliance
-- Paste this whole file into Supabase Dashboard → SQL Editor → Run.
-- Adds:
--   · centres + centre_rollout — every approved Standard becomes
--     a launch-checklist item for each new centre
--   · centre_rollout.spawned_actionable_id — the Launch Playbook:
--     a checklist item can spawn a pre-filled actionable
--   · compliance_items — the compliance & renewal calendar
--     (certifications, audits, insurance, AMCs, recurring bills)
-- Safe to run more than once (also on top of the earlier version).
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

-- Launch Playbook: a rollout item can spawn a pre-filled actionable
alter table centre_rollout add column if not exists
  spawned_actionable_id uuid references actionables(id) on delete set null;

-- ---------- compliance & renewal calendar ----------
create table if not exists compliance_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'other'
    check (category in ('certification','audit','insurance','contract','bill','other')),
  centre_id uuid references centres(id) on delete set null,
  owner_staff_id uuid references staff(id) on delete set null,
  frequency text not null default 'yearly'
    check (frequency in ('once','monthly','quarterly','half_yearly','yearly')),
  next_due date not null,
  lead_days int not null default 30,
  notes text,
  active boolean not null default true,
  last_spawned_due date,
  last_actionable_id uuid references actionables(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- RLS (same permissive posture as the rest of the app) ----------
alter table centres enable row level security;
alter table centre_rollout enable row level security;
alter table compliance_items enable row level security;

drop policy if exists anon_all_centres on centres;
drop policy if exists anon_all_centre_rollout on centre_rollout;
drop policy if exists anon_all_compliance on compliance_items;
create policy anon_all_centres on centres for all using (true) with check (true);
create policy anon_all_centre_rollout on centre_rollout for all using (true) with check (true);
create policy anon_all_compliance on compliance_items for all using (true) with check (true);

-- ---------- seed: the two live centres + Centre #3 ----------
insert into centres (name, status, sort_order) values
  ('Cochin Centre', 'live', 1),
  ('Calicut Centre', 'live', 2),
  ('Mangalore Centre', 'launching', 3)
on conflict (name) do nothing;

-- Done! Refresh actionables.html — the Centre Rollout view lights up.

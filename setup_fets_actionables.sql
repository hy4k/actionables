-- ============================================================
-- FETS ACTIONABLES — one-time setup for project qmjsfshhnwjtdmraatcv
-- Paste this whole file into Supabase Dashboard → SQL Editor → Run.
-- Creates schema, storage, Google Chat trigger, and pre-loads
-- ACT-01 (Nimmy M) and ACT-02 (Shimna) with their collected data.
-- ============================================================

-- ---------- tables ----------
create table if not exists staff (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  role text not null default 'member' check (role in ('admin','member')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists actionables (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text,
  status text not null default 'pending' check (status in ('pending','in_progress','submitted','completed')),
  due_date date,
  created_by uuid references staff(id),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists actionable_assignments (
  id uuid primary key default gen_random_uuid(),
  actionable_id uuid not null references actionables(id) on delete cascade,
  staff_id uuid not null references staff(id) on delete cascade,
  member_role text not null default 'member' check (member_role in ('lead','member')),
  assigned_at timestamptz not null default now(),
  unique (actionable_id, staff_id)
);

create table if not exists actionable_updates (
  id uuid primary key default gen_random_uuid(),
  actionable_id uuid not null references actionables(id) on delete cascade,
  staff_id uuid references staff(id),
  kind text not null default 'update' check (kind in ('update','instruction','status_change','submission')),
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists actionable_data (
  id uuid primary key default gen_random_uuid(),
  actionable_id uuid not null references actionables(id) on delete cascade,
  staff_id uuid references staff(id),
  label text not null,
  content jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists actionable_files (
  id uuid primary key default gen_random_uuid(),
  actionable_id uuid not null references actionables(id) on delete cascade,
  staff_id uuid references staff(id),
  file_name text not null,
  storage_path text not null,
  size_bytes bigint,
  created_at timestamptz not null default now()
);

create table if not exists app_settings (
  key text primary key,
  value text,
  updated_at timestamptz not null default now()
);

-- ---------- RLS (permissive: small trusted team, app uses anon key) ----------
alter table staff enable row level security;
alter table actionables enable row level security;
alter table actionable_assignments enable row level security;
alter table actionable_updates enable row level security;
alter table actionable_data enable row level security;
alter table actionable_files enable row level security;
alter table app_settings enable row level security;

drop policy if exists anon_all_staff on staff;
drop policy if exists anon_all_actionables on actionables;
drop policy if exists anon_all_assignments on actionable_assignments;
drop policy if exists anon_all_updates on actionable_updates;
drop policy if exists anon_all_data on actionable_data;
drop policy if exists anon_all_files on actionable_files;
drop policy if exists anon_all_settings on app_settings;
create policy anon_all_staff on staff for all using (true) with check (true);
create policy anon_all_actionables on actionables for all using (true) with check (true);
create policy anon_all_assignments on actionable_assignments for all using (true) with check (true);
create policy anon_all_updates on actionable_updates for all using (true) with check (true);
create policy anon_all_data on actionable_data for all using (true) with check (true);
create policy anon_all_files on actionable_files for all using (true) with check (true);
create policy anon_all_settings on app_settings for all using (true) with check (true);

-- ---------- storage bucket for attachments ----------
insert into storage.buckets (id, name, public) values ('attachments','attachments', true)
on conflict (id) do nothing;
drop policy if exists anon_upload_attachments on storage.objects;
drop policy if exists anon_read_attachments on storage.objects;
drop policy if exists anon_delete_attachments on storage.objects;
create policy anon_upload_attachments on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'attachments');
create policy anon_read_attachments on storage.objects
  for select to anon, authenticated using (bucket_id = 'attachments');
create policy anon_delete_attachments on storage.objects
  for delete to anon, authenticated using (bucket_id = 'attachments');

-- ---------- Google Chat notifications ----------
create extension if not exists pg_net;

create or replace function notify_gchat() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  url text; act record; who text; label text;
begin
  select value into url from app_settings where key = 'gchat_webhook';
  if url is null or length(trim(url)) = 0 then return new; end if;
  select code, title into act from actionables where id = new.actionable_id;
  select name into who from staff where id = new.staff_id;
  label := case new.kind
    when 'instruction' then '📌 INSTRUCTION'
    when 'submission' then '📤 SUBMITTED'
    when 'status_change' then '🔄 STATUS'
    else '💬 UPDATE' end;
  perform net.http_post(
    url := url,
    body := jsonb_build_object('text',
      '*' || act.code || ' · ' || act.title || '*' || E'\n' ||
      label || ' — ' || coalesce(who, 'Someone') || E'\n' || new.message),
    headers := '{"Content-Type":"application/json"}'::jsonb
  );
  return new;
exception when others then
  return new;
end $$;

drop trigger if exists trg_notify_gchat on actionable_updates;
create trigger trg_notify_gchat
after insert on actionable_updates
for each row execute function notify_gchat();

-- ============================================================
-- SEED DATA
-- ============================================================
insert into staff (name, role) values
  ('Midhun', 'admin'),
  ('Nimmy M', 'member'),
  ('Shimna', 'member')
on conflict (name) do nothing;

insert into actionables (code, title, description, status, created_by)
values
  ('ACT-01', 'Centre Overheads',
   E'Track every recurring bill for all FETS locations — internet, phone, electricity, rent, DG, water, waste removal.\nCovers Cochin centre, Calicut centre and the Calicut office guest house.\nPhase 1: internet & telephone details. Electricity comes in the next phase.',
   'in_progress', (select id from staff where name='Midhun')),
  ('ACT-02', 'Client Registry',
   E'One master registry for every exam client — Pearson VUE, ACCA, CELPIP, PSI and more.\nPer client: site codes, certified staff, installed software, support desk and contact persons.\nPlus exams delivered, login/technical requirements and client-specific procedures.',
   'in_progress', (select id from staff where name='Midhun'))
on conflict (code) do nothing;

insert into actionable_assignments (actionable_id, staff_id, member_role)
values
  ((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'), 'lead'),
  ((select id from actionables where code='ACT-02'), (select id from staff where name='Shimna'), 'lead')
on conflict do nothing;

insert into actionable_updates (actionable_id, staff_id, kind, message) values
  ((select id from actionables where code='ACT-01'), (select id from staff where name='Midhun'), 'instruction',
   'Start with internet and telephone connection details for Cochin centre, Calicut centre and the Calicut office guest house. Electricity and other utilities will be added in the next phase.'),
  ((select id from actionables where code='ACT-02'), (select id from staff where name='Midhun'), 'instruction',
   'Build the registry client by client. For each client capture site codes, certified staff, installed software, support desk details, contact persons, exams delivered, login/technical requirements and any client-specific procedures.');

-- ---------- ACT-01 collected data (from Nimmy M''s network sheet) ----------
insert into actionable_data (actionable_id, staff_id, label, content) values
((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'),
 'Cochin Centre · Internet — Airtel',
 jsonb_build_object('text', E'Portal: https://www.airtel.in/business/thanksforbusiness/login/\nConnection ID: 20019572185\nPortal user: mithun@fets.in / @Fets2026\nWiFi: Airtel_mith_6000 / air65691\nPlan: 3999 · 1 Gbps · Rent ₹4,832.50\nBill date: 24th of every month')),
((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'),
 'Cochin Centre · Internet — Jio',
 jsonb_build_object('text', E'Portal: https://enterprise.jio.com/Enterprise/myjio-ent/login/index.html#/\nPortal user: niyaskizhakootkassim_6 / Admin@123\nNetwork type: STATIC\nWiFi: fetsstatic / @Fets 2026\nPlan: 4001 · 1 Gbps with 4500 GB data · Rent ₹4,001\nBill date: 02-03-2026 (as per sheet)')),
((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'),
 'Calicut Centre · Internet — Airtel',
 jsonb_build_object('text', E'Portal: https://www.airtel.in/business/thanksforbusiness/login/\nConnection ID: 20019572185 (same ID listed for both centres in sheet — please verify)\nPortal user: mithun@fets.in / @Fets2026\nWiFi: Airtel_mith_3992 / Air@28810\nPlan: 3999 · 1 Gbps · Rent ₹4,832.50\nBill date: 24th of every month')),
((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'),
 'Calicut Centre · Internet — Jio',
 jsonb_build_object('text', E'Portal: https://enterprise.jio.com/Enterprise/myjio-ent/login/index.html#/\nPortal user: niyaskizhakootkassim_6 / @Fets 2026\nWiFi: jioFiber_forun / @Fets2025\nPlan: 1001 · 200 Mbps with 3300 GB data · Rent ₹1,001\nBill date: 05-03-2026 (as per sheet)'));

-- ---------- ACT-02 collected data (from Shimna''s site codes sheet) ----------
insert into actionable_data (actionable_id, staff_id, label, content) values
((select id from actionables where code='ACT-02'), (select id from staff where name='Shimna'),
 'Calicut Centre · Site Codes',
 jsonb_build_object('text', E'PEARSON VUE: 88419\nCMA: 4960\nCELPIP: 5485\nITTS: IT217\nPSI: 18133')),
((select id from actionables where code='ACT-02'), (select id from staff where name='Shimna'),
 'Cochin Centre · Site Codes',
 jsonb_build_object('text', E'PEARSON VUE: 91529\nCMA: 5290\nCELPIP: 5486\nITTS: IT215\nPSI: — (not listed for Cochin)'));

-- Progress notes so the feeds reflect the work already done
insert into actionable_updates (actionable_id, staff_id, kind, message) values
  ((select id from actionables where code='ACT-01'), (select id from staff where name='Nimmy M'), 'update',
   'Added internet connection details (Airtel + Jio) for both Cochin and Calicut centres — portals, WiFi credentials, plans and bill dates. Guest house and telephone lines next.'),
  ((select id from actionables where code='ACT-02'), (select id from staff where name='Shimna'), 'update',
   'Added site codes for Calicut and Cochin: Pearson VUE, CMA, CELPIP, ITTS and PSI (Calicut). Next: certified staff and support desk details per client.');

-- Done! Open actionables.html and everything will be live.

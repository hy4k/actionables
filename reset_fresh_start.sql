-- ============================================================
-- FETS ACTIONABLES — FRESH START
-- ⚠ DELETES EVERYTHING: all actionables, work logs, collected
--   data, files, staff, rollout items, compliance items.
--   This cannot be undone. Paste into Supabase SQL Editor → Run.
-- Keeps: table structure, the Google Chat webhook setting.
-- Re-seeds: Midhun (admin) + the three centres, with the new
--   centre named Mangalore.
-- Add the rest of the team afterwards inside the app:
--   Assign Actionable page → ＋ ADD STAFF MEMBER.
-- ============================================================

truncate table
  actionable_updates,
  actionable_data,
  actionable_files,
  actionable_assignments,
  centre_rollout,
  compliance_items,
  actionables,
  centres,
  staff
cascade;

-- wipe every uploaded attachment
delete from storage.objects where bucket_id = 'attachments';

-- keep the Google Chat webhook; uncomment the next line to clear it too
-- delete from app_settings;

-- re-seed the essentials
insert into staff (name, role) values ('Midhun', 'admin');

insert into centres (name, status, sort_order) values
  ('Cochin Centre',    'live',      1),
  ('Calicut Centre',   'live',      2),
  ('Mangalore Centre', 'launching', 3);

-- Done. Refresh the app — clean slate, Mangalore rollout board ready.

-- ============================================================
-- FETS ACTIONABLES — add the team as staff records
-- Safe, idempotent. Does NOT touch Supabase Auth — just prepares
-- the app's staff table so the auto-link trigger can match each
-- person the moment their login is created.
--
-- ORDER MATTERS:
--   1. Run this file FIRST.
--   2. THEN go to Supabase → Authentication → Users → Add user
--      for each person below, using the SAME email, password
--      "123456", and tick "Auto confirm". The trigger links them
--      to their staff row automatically the instant you create it.
--   (If you ever do it in the other order, just re-run this file —
--    the safety re-sync at the bottom catches anyone missed.)
-- ============================================================

insert into staff (name, role, email) values
  ('Aysha Satha',    'member', 'aysha@fets.in'),
  ('Lazeem P',       'member', 'lazeem@fets.in'),
  ('Linofer K',      'member', 'linofer@fets.in'),
  ('Niyas Kassim',   'member', 'niyas@fets.in'),
  ('Nimmy M',        'member', 'nimmy@fets.in'),
  ('Ramseena Salim', 'member', 'ramseena@fets.in'),
  ('Shimna K Navas', 'member', 'shimna@fets.in'),
  ('Naeema MM',      'member', 'naeema@fets.in')
on conflict (name) do update set email = excluded.email;

-- safety re-sync: links anyone above whose Supabase Auth user already exists
update staff s set auth_user_id = u.id
from auth.users u
where lower(u.email) = lower(s.email) and s.auth_user_id is null;

-- check the result: "linked" should be true once both steps are done
select name, email, auth_user_id is not null as linked from staff order by name;

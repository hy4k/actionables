-- ============================================================
-- FETS ACTIONABLES — AUTH UPGRADE (email + password, real RLS)
--
-- ⚠ RUN THIS ONLY WHEN YOU ARE READY TO SWITCH THE APP TO LOGIN.
--   After this runs, the anon key can READ NOTHING and WRITE
--   NOTHING — every request must come from a signed-in user.
--   Deploy the auth version of actionables.html at the same time.
--
-- ORDER OF OPERATIONS (one sitting, ~15 minutes):
--   1. Supabase Dashboard → Authentication → Users → "Add user"
--      → create one user per staff member (email + password,
--      tick "Auto confirm"). Use the same emails as step 2.
--   2. Edit the three UPDATE lines in section B below with the
--      real emails, then paste this WHOLE file into SQL Editor → Run.
--   3. Upload the new actionables.html to your host.
--   4. Everyone signs in with their email + password. Done.
--
-- New staff later: Add user in Authentication → Users, then in the
-- app use ＋ ADD STAFF MEMBER with the same email — they link up
-- automatically (or run:  update staff set email='x@y' where name='…').
-- ============================================================

-- ---------- A. staff ↔ auth link columns ----------
alter table staff add column if not exists email text unique;
alter table staff add column if not exists auth_user_id uuid unique references auth.users(id);

-- ---------- B. set each staff member's login email (EDIT THESE) ----------
update staff set email = 'mithun@fets.in' where name = 'Midhun';   -- applied to production 2026-07-04
update staff set email = 'nimmy@fets.in'      where name = 'Nimmy M';   -- ← EDIT
update staff set email = 'shimna@fets.in'     where name = 'Shimna';    -- ← EDIT

-- link any auth users that already exist for those emails
update staff s set auth_user_id = u.id
from auth.users u
where lower(u.email) = lower(s.email) and s.auth_user_id is null;

-- and auto-link future auth users by email
create or replace function link_staff_auth() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update staff set auth_user_id = new.id
  where lower(email) = lower(new.email) and auth_user_id is null;
  return new;
end $$;
drop trigger if exists trg_link_staff_auth on auth.users;
create trigger trg_link_staff_auth
after insert on auth.users
for each row execute function link_staff_auth();

-- ---------- C. helper functions used by the policies ----------
create or replace function current_staff_id() returns uuid
language sql stable security definer set search_path = public as
$$ select id from staff where auth_user_id = auth.uid() and active $$;

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from staff where auth_user_id = auth.uid() and role = 'admin' and active) $$;

create or replace function is_on_actionable(act uuid) returns boolean
language sql stable security definer set search_path = public as
$$ select exists (
     select 1 from actionable_assignments aa
     join staff s on s.id = aa.staff_id
     where aa.actionable_id = act and s.auth_user_id = auth.uid()) $$;

-- ---------- D. drop the open anon policies ----------
drop policy if exists anon_all_staff on staff;
drop policy if exists anon_all_actionables on actionables;
drop policy if exists anon_all_assignments on actionable_assignments;
drop policy if exists anon_all_updates on actionable_updates;
drop policy if exists anon_all_data on actionable_data;
drop policy if exists anon_all_files on actionable_files;
drop policy if exists anon_all_settings on app_settings;
drop policy if exists anon_all_centres on centres;
drop policy if exists anon_all_centre_rollout on centre_rollout;
drop policy if exists anon_all_compliance on compliance_items;

-- ---------- E. real policies (signed-in users only) ----------
-- staff: everyone signed in can see the team; only admin manages it
drop policy if exists auth_read_staff on staff;
drop policy if exists admin_write_staff on staff;
create policy auth_read_staff on staff for select to authenticated using (true);
create policy admin_write_staff on staff for all to authenticated
  using (is_admin()) with check (is_admin());

-- actionables: read all; create/delete admin; update admin or the assigned team
drop policy if exists auth_read_actionables on actionables;
drop policy if exists admin_insert_actionables on actionables;
drop policy if exists team_update_actionables on actionables;
drop policy if exists admin_delete_actionables on actionables;
create policy auth_read_actionables on actionables for select to authenticated using (true);
create policy admin_insert_actionables on actionables for insert to authenticated
  with check (is_admin());
create policy team_update_actionables on actionables for update to authenticated
  using (is_admin() or is_on_actionable(id))
  with check (is_admin() or is_on_actionable(id));
create policy admin_delete_actionables on actionables for delete to authenticated
  using (is_admin());

-- assignments: read all; only admin assigns/removes people
drop policy if exists auth_read_assignments on actionable_assignments;
drop policy if exists admin_write_assignments on actionable_assignments;
create policy auth_read_assignments on actionable_assignments for select to authenticated using (true);
create policy admin_write_assignments on actionable_assignments for all to authenticated
  using (is_admin()) with check (is_admin());

-- updates: read all; post as yourself; instructions are admin-only; admin can delete
drop policy if exists auth_read_updates on actionable_updates;
drop policy if exists self_insert_updates on actionable_updates;
drop policy if exists admin_delete_updates on actionable_updates;
create policy auth_read_updates on actionable_updates for select to authenticated using (true);
create policy self_insert_updates on actionable_updates for insert to authenticated
  with check (staff_id = current_staff_id() and (kind <> 'instruction' or is_admin()));
create policy admin_delete_updates on actionable_updates for delete to authenticated
  using (is_admin());

-- collected data: read all; add/edit/delete only admin or that actionable's team
drop policy if exists auth_read_data on actionable_data;
drop policy if exists team_insert_data on actionable_data;
drop policy if exists team_update_data on actionable_data;
drop policy if exists team_delete_data on actionable_data;
create policy auth_read_data on actionable_data for select to authenticated using (true);
create policy team_insert_data on actionable_data for insert to authenticated
  with check (staff_id = current_staff_id() and (is_admin() or is_on_actionable(actionable_id)));
create policy team_update_data on actionable_data for update to authenticated
  using (is_admin() or is_on_actionable(actionable_id))
  with check (is_admin() or is_on_actionable(actionable_id));
create policy team_delete_data on actionable_data for delete to authenticated
  using (is_admin() or is_on_actionable(actionable_id));

-- files: same rule as collected data
drop policy if exists auth_read_files on actionable_files;
drop policy if exists team_insert_files on actionable_files;
drop policy if exists team_delete_files on actionable_files;
create policy auth_read_files on actionable_files for select to authenticated using (true);
create policy team_insert_files on actionable_files for insert to authenticated
  with check (staff_id = current_staff_id() and (is_admin() or is_on_actionable(actionable_id)));
create policy team_delete_files on actionable_files for delete to authenticated
  using (is_admin() or is_on_actionable(actionable_id));

-- settings (Google Chat webhook): read all; only admin changes it
drop policy if exists auth_read_settings on app_settings;
drop policy if exists admin_write_settings on app_settings;
create policy auth_read_settings on app_settings for select to authenticated using (true);
create policy admin_write_settings on app_settings for all to authenticated
  using (is_admin()) with check (is_admin());

-- centres: read all; only admin manages centres
drop policy if exists auth_read_centres on centres;
drop policy if exists admin_write_centres on centres;
create policy auth_read_centres on centres for select to authenticated using (true);
create policy admin_write_centres on centres for all to authenticated
  using (is_admin()) with check (is_admin());

-- centre rollout: read all; any signed-in staff can tick items
drop policy if exists auth_read_rollout on centre_rollout;
drop policy if exists auth_write_rollout on centre_rollout;
drop policy if exists admin_delete_rollout on centre_rollout;
create policy auth_read_rollout on centre_rollout for select to authenticated using (true);
create policy auth_write_rollout on centre_rollout for insert to authenticated with check (true);
drop policy if exists auth_update_rollout on centre_rollout;
create policy auth_update_rollout on centre_rollout for update to authenticated
  using (true) with check (true);
create policy admin_delete_rollout on centre_rollout for delete to authenticated
  using (is_admin());

-- compliance calendar: read all; only admin creates/edits/deletes items
-- (the auto-spawn engine only runs in the admin's browser on this build,
--  because spawning also inserts actionables, which is admin-only above)
drop policy if exists auth_read_compliance on compliance_items;
drop policy if exists admin_write_compliance on compliance_items;
create policy auth_read_compliance on compliance_items for select to authenticated using (true);
create policy admin_write_compliance on compliance_items for all to authenticated
  using (is_admin()) with check (is_admin());

-- ---------- F. storage: attachments now need a login too ----------
drop policy if exists anon_upload_attachments on storage.objects;
drop policy if exists anon_read_attachments on storage.objects;
drop policy if exists anon_delete_attachments on storage.objects;
drop policy if exists auth_upload_attachments on storage.objects;
drop policy if exists auth_read_attachments on storage.objects;
drop policy if exists auth_delete_attachments on storage.objects;
create policy auth_upload_attachments on storage.objects
  for insert to authenticated with check (bucket_id = 'attachments');
create policy auth_read_attachments on storage.objects
  for select to authenticated using (bucket_id = 'attachments');
create policy auth_delete_attachments on storage.objects
  for delete to authenticated using (bucket_id = 'attachments');

-- Known limits (accepted): the bucket stays public for direct file
-- links, and an assigned member could technically flip their own
-- actionable's status via the API — both are fine for a small
-- trusted team and a huge step up from the open anon policies.

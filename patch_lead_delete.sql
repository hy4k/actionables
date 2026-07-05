-- ============================================================
-- FETS ACTIONABLES — lead delete permission
-- Only needed if you already ran patch_auth_upgrade.sql (login is on).
-- Lets an actionable's LEAD delete it, not just the admin — matching
-- the app's ✏️ EDIT / 🗑️ DELETE buttons. Safe to run more than once.
-- ============================================================

create or replace function is_lead_on_actionable(act uuid) returns boolean
language sql stable security definer set search_path = public as
$$ select exists (
     select 1 from actionable_assignments aa
     join staff s on s.id = aa.staff_id
     where aa.actionable_id = act and s.auth_user_id = auth.uid() and aa.member_role = 'lead') $$;

drop policy if exists admin_delete_actionables on actionables;
create policy admin_delete_actionables on actionables for delete to authenticated
  using (is_admin() or is_lead_on_actionable(id));

-- Done. Leads can now delete their own open actionables; admin can delete any.

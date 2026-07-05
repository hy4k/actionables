# FETS Actionables ⚡

Task & standardisation platform for FETS test centres (Cochin · Calicut · Centre #3 soon).
Single-file web app, comic-doodle design, Supabase backend.

## Files

| File | What it is |
|---|---|
| `actionables.html` | The entire app. Open locally or host anywhere (e.g. Hostinger). |
| `setup_fets_actionables.sql` | One-time database setup — paste into Supabase SQL Editor and Run. |
| `patch_fets_os.sql` | The FETS OS tables: Centre Rollout, Launch Playbook, Compliance Calendar — run once (safe to re-run). |
| `patch_delete_policy.sql` | Only if your DB was created with an older setup script. |
| `patch_auth_upgrade.sql` | **The auth switch.** Email+password login + real RLS. Read its header before running. |
| `reset_fresh_start.sql` | ⚠ Wipes ALL data and re-seeds Midhun + the three centres (Mangalore launching). |
| `add_team_members.sql` | Adds named staff records ready to link to their Supabase Auth logins. |
| `patch_lead_delete.sql` | Lets an actionable's lead delete it too (only needed after the auth switch). |
| `deploy_act.sh` | Deploys the app to fets.live/act on the VPS (see script header). |
| `PROJECT_CONTEXT.md` | **Full project memory.** Read this first — new developers AND Claude sessions. |

## Quick start

1. Supabase project → SQL Editor → run `setup_fets_actionables.sql` (once).
2. SQL Editor → run `patch_fets_os.sql` (once) — enables the Centre Rollout board, Launch Playbook and Compliance Calendar.
3. Open `actionables.html` (or upload to your host) — dashboard lights up with ACT-01 & ACT-02.
4. Optional: Chat Alerts page → paste a Google Chat incoming-webhook URL for team notifications.

## Continuing work with Claude on any computer

Clone this repo, open a Claude (Cowork) session with the repo folder connected, and say:

> "Read PROJECT_CONTEXT.md — let's continue the FETS Actionables project."

## Switching on login (this branch)

This version of `actionables.html` requires sign-in. Go-live checklist — do all of it in one sitting:

1. Supabase → **Authentication → Users → Add user** for each staff member (tick *Auto confirm*).
2. Edit the emails in section B of `patch_auth_upgrade.sql`, then run the whole file in the SQL Editor.
3. Upload this `actionables.html` to your host, replacing the old one.
4. Everyone signs in with email + password. Admin powers now enforced by the database, not just the UI.

⚠️ **Keep this repository PRIVATE** — `actionables.html` embeds the Supabase anon key.
After the auth upgrade the anon key alone can read/write nothing, but private is still right.

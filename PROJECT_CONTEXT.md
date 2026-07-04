# FETS Actionables — Project Context (Claude memory file)

> **Purpose of this file:** complete handover context. If you are Claude (or any developer)
> picking this project up fresh, read this file and you know the whole story.
> Owner: **Midhun** (midhunnr@gmail.com), founder of Forun Testing & Educational Services (FETS), Calicut, Kerala.

## 1. What this is and WHY

A task-management platform called **Actionables** for FETS staff. Its real mission:
**standardising the Cochin and Calicut test centres before FETS opens Centre #3.**
Each "actionable" is a data-collection/standardisation task (e.g. collect all internet
bills, build a client registry). When approved, it becomes a **Standard** — a reusable
reference document comparing centres side by side, applied to future centres.

## 2. Architecture

- **Single-file web app:** `actionables.html` — no build step, no framework. Vanilla JS +
  supabase-js v2 from CDN. Host anywhere (Hostinger) or open locally.
- **Backend:** Supabase project **qmjsfshhnwjtdmraatcv** (Midhun's own account, NOT the
  account connected to earlier Cowork sessions).
  - URL: `https://qmjsfshhnwjtdmraatcv.supabase.co`
  - App uses the **anon key** (hardcoded in actionables.html).
  - `setup_fets_actionables.sql` = full one-time setup (schema, RLS, storage, trigger, seed data).
  - `patch_fets_os.sql` = adds the FETS OS Centre Rollout tables (centres, centre_rollout) + seed centres.
  - `patch_delete_policy.sql` = for DBs created with the pre-delete-policy script version.
- **A retired mirror** exists at project `sdaaynkobntgkqlqrjko` ("fets-actionables", Mumbai,
  in the Supabase account connected to the original Cowork session) — used for testing; not production.

### Database schema (all in `public`, RLS enabled with allow-all anon policies)
- `staff` (id, name unique, role: admin|member, active) — Midhun=admin; Nimmy M, Shimna=members
- `actionables` (id, **code** unique e.g. ACT-01, title, description, status:
  pending → in_progress → submitted → completed, due_date, created_by, completed_at)
- `actionable_assignments` (actionable↔staff, member_role: lead|member)
- `actionable_updates` (kind: update | instruction | status_change | submission, message)
  — **instructions = numbered procedure steps, admin-only**; others = Work Log
- `actionable_data` (label, content jsonb `{text: "..."}`) — the collected data entries
- `actionable_files` (file_name, storage_path → public bucket `attachments`, size_bytes)
- `app_settings` (key/value) — key `gchat_webhook` holds the Google Chat incoming-webhook URL
- `centres` (name unique, status: live|launching|planned, sort_order, launched_at) — seeded:
  Cochin Centre (live), Calicut Centre (live), Centre #3 (launching). Requires `patch_fets_os.sql`.
- `centre_rollout` (centre↔actionable unique pair, status: not_started|in_progress|done|na,
  note, updated_by, spawned_actionable_id) — one row per approved Standard per not-yet-live centre
- `compliance_items` (title, category: certification|audit|insurance|contract|bill|other,
  centre_id?, owner_staff_id?, frequency: once|monthly|quarterly|half_yearly|yearly, next_due,
  lead_days, notes, active, last_spawned_due, last_actionable_id) — the renewal calendar
- Trigger `trg_notify_gchat` (pg_net): every insert into actionable_updates POSTs to the
  Google Chat webhook if set. Never blocks on failure.

### Important data convention
Data-entry labels follow **`<Centre> · <Item>`** (e.g. `Cochin Centre · Internet — Airtel`).
The Standards view splits on `·`: part before = table **column**, part after = table **row**.
Keep this convention or the comparison table breaks.

## 3. App behaviour

- **No login.** Identity: "WHO ARE YOU?" modal appears only when someone tries to act
  (or via the top-bar user chip); stored in localStorage (`fets_me`). Admin-only UI
  (Assign, Chat Alerts, Add Step, Approve) keys off the picked identity being Midhun.
- **Shell (2026-07 hub redesign, per Midhun):** NO left sidebar, NO hero banner, NO metric
  tiles, NO "work in motion" grid. A slim navy top bar (logo → dashboard, user chip) sits
  above every view. The Dashboard IS the menu: big comic tiles — 🎯 ACTIONABLES (all statuses
  in one view), 🚀 <centre> ROLLOUT (named after the launching centre, e.g. MANGALORE),
  📅 COMPLIANCE, plus admin tiles ✨ ASSIGN and 🔔 CHAT ALERTS — followed by the compliance
  radar, rollout strip and team-overview strips. Every sub-view has a ← DASHBOARD button.
- **Actionables view = everything**: sections IN PROGRESS / NOT STARTED / AWAITING REVIEW /
  STANDARDS LIBRARY, with the viewer's own work floated to the top of each section.
  (The old My/Team/Pending/Completed views were merged into this per Midhun.)
- **Actionable page (open):** header card (code, title, status, buttons + point-wise
  "WHAT'S THIS FOR?" + team chips + facts) → 📌 INSTRUCTIONS — STEP BY STEP (numbered,
  admin adds steps) → 🔨 WORK LOG (anyone posts) → 🗂️ COLLECTED DATA + 📎 FILES
  (edit/delete/add **only for Midhun + assigned team**; enforced client-side only).
- **Actionable page (completed) = Standard document:** APPROVED STANDARD stamp, purpose,
  prepared-by, **auto-generated centre-comparison table**, reference files, collapsible
  work history, PRINT/PDF button. Nav item is "Standards 📘".
- Codes auto-generate: ACT-01, ACT-02, … (max existing number + 1).
- Flow: pending → START WORK → in_progress → SUBMIT AS FINISHED → submitted →
  Midhun APPROVE (→ Standard) or SEND BACK.
- **FETS OS · Centre Rollout (nav "Centre Rollout 🚀"):** the app's end-game. Every approved
  Standard automatically becomes a launch-checklist row for each not-yet-live centre
  (client-side sync inserts missing `centre_rollout` rows when the view opens). Anyone can
  cycle an item's status (not started → in progress → done → n/a) and add a note; marking
  "done" also posts to that standard's Work Log (so Google Chat pings). Per-centre progress
  bar; at 100% the admin gets 🎉 MARK LIVE (sets centre live + launched_at). Admin can
  ＋ ADD CENTRE (planned) and ▶ START LAUNCH (planned → launching). Dashboard shows a
  "Centre rollout" strip with per-centre progress while any centre is launching/planned.
  If the tables are missing the view shows a run-patch_fets_os.sql setup card instead.
- **Launch Playbook:** on a rollout item the admin can 🚀 SPAWN TASK — creates a pre-filled
  actionable "<Centre> · <Standard title>" whose brief says match-or-beat the live centres
  and whose first instruction lists every item from the standard's collected data. The item
  links to the task (↗ ACT-xx) and turns done automatically when the task is approved.
  Spawned launch tasks are excluded from becoming new rollout checklist rows (no loops).
- **Compliance Calendar (nav "Compliance 📅"):** `compliance_items` = expiring/recurring
  obligations (PVTC/CELPIP certs, site audits, insurance, AMCs, monthly bills). A client-side
  engine runs at boot: any active item inside its lead window (lead_days before next_due,
  clamped below the cycle length) spawns its actionable once per cycle — claim-first update
  guards against double-spawn from two tabs — assigns the owner as lead, carries notes into
  the brief, and posts a status update (= Google Chat ping). next_due then advances by the
  frequency; 'once' items deactivate. View groups OVERDUE / DUE SOON / SCHEDULED / PAUSED
  with admin add/edit/pause/delete. Dashboard shows a "Compliance radar" strip when anything
  is due. Engine runs whenever anyone opens the app (no server); pg_cron is future hardening.

## 4. Design language (do not drift from this)

Comic doodle / pop-art, derived from a reference button Midhun supplied:
- Colors: yellow `#ffea00`, pink `#ff007f`, cyan `#00d4ff`, orange `#ff5100`, ink `#111`,
  paper `#FFFDF2` with dotted background.
- Fonts: **Bangers** (headings/badges), **Comic Neue** (body). White-outline text shadows.
- 3px solid ink borders, sketchy radii (`255px 15px 225px 15px / 15px 225px 15px 255px`),
  layered hard shadows (pink → cyan → ink), wobble-on-hover buttons, ★ and ⚡ accents.
- Midhun wants spacious, vibrant, unconventional layouts. He is highly design-sensitive.

## 5. Current state / seeded content

- ACT-01 **Centre Overheads** — lead Nimmy M, in_progress. 4 data entries: Airtel + Jio
  internet for Cochin & Calicut (portals, credentials, plans, bill dates). Phase 2 will add
  electricity, guest house, telephones.
- ACT-02 **Client Registry** — lead Shimna, in_progress. 2 data entries: site codes for
  Calicut & Cochin (Pearson VUE, CMA, CELPIP, ITTS, PSI). Next: certified staff, support
  desks, contacts per client.
- Known data-quality flags: same Airtel connection ID (20019572185) listed for both centres
  (needs verification); Jio "bill dates" were calendar dates in the source sheet.
- Source spreadsheets: `Site codes.xlsx` (Shimna), `NET WORK DETAILS KOCHI AND CALICUT (1).xlsx`
  (Nimmy) — should be uploaded as attachments to ACT-02 / ACT-01 via the Files panel.

## 6. Security posture (known, accepted for now)

- Anon key in page source + allow-all RLS ⇒ anyone with the link/key can read & write everything.
- Edit/delete permissions are client-side only (cosmetic against technical users).
- ACT-01 contains plaintext WiFi/ISP-portal passwords.
- **Agreed next step: BEFORE Centre #3 staff onboard → Supabase Auth (email+password),
  staff linked to auth.uid, real RLS (admin-only instructions/approval, team-only edits).**
  ≈ one working session. Keep repo PRIVATE because of the key.

## 7. Backlog / ideas discussed

1. Auth upgrade (above) — top priority when team grows.
2. Upload the two source xlsx files into the app.
3. Google Chat webhook: Midhun to create in his Workspace Chat space
   (space → Apps & integrations → Webhooks) and paste into Chat Alerts page.
4. Phase 2 of ACT-01 (electricity, rent, DG, guest house, telephone lines).
5. Possible future: export Standard as xlsx/pdf file, per-step done-checkboxes, deeper
   Google Workspace integration.

## 8. How Midhun works (for Claude)

- Iterative, design-first, appreciates bold creative UI and humour. Business ↔ playful mix.
- Wants direct, factual answers with honest trade-offs flagged (e.g. security caveats).
- Stack preferences: Supabase, single-file/no-build where possible, Astro/Hostinger for sites,
  n8n & WhatsApp Cloud API elsewhere in his business.

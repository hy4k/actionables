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
- Trigger `trg_notify_gchat` (pg_net): every insert into actionable_updates POSTs to the
  Google Chat webhook if set. Never blocks on failure.

### Important data convention
Data-entry labels follow **`<Centre> · <Item>`** (e.g. `Cochin Centre · Internet — Airtel`).
The Standards view splits on `·`: part before = table **column**, part after = table **row**.
Keep this convention or the comparison table breaks.

## 3. App behaviour

- **No login.** Front page = Team Dashboard: one card per staff member, assigned work as
  bright chips, completed as green struck-through chips. Everything viewable by everyone.
- Identity: "WHO ARE YOU?" modal appears only when someone tries to act; stored in
  localStorage (`fets_me`). Admin-only UI (Assign, Chat Alerts, Add Step, Approve) keys off
  the picked identity being Midhun.
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

## 4. Design language (Actionables Studio v2)

The original comic-doodle UI was upgraded into a spacious operations workspace in July 2026:
- Core palette: navy `#17243a`, warm paper `#f4f4ee`, yellow `#ffd84d`, coral `#ff6b55`,
  and teal `#20b7a2`. Playful FETS accents remain, but content surfaces are calm and structured.
- Fonts: **Space Grotesk** for display hierarchy and **DM Sans** for interface/body copy.
- Dashboard hierarchy: standards-readiness hero, live metrics, work-in-motion cards, approved
  standards, and team ownership. Lists use progress, ownership, due date and search.
- Desktop uses a dark fixed navigation rail. Mobile uses a sticky identity header and fixed
  bottom navigation, with admin actions shown only to the admin identity.
- Prefer generous whitespace, rounded 18–30px surfaces, fine borders and soft depth. Avoid
  reverting to dense hard-shadow comic cards across the full interface.

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

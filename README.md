# FETS Actionables ⚡

Task & standardisation platform for FETS test centres (Cochin · Calicut · Centre #3 soon).
Single-file web app, comic-doodle design, Supabase backend.

## Files

| File | What it is |
|---|---|
| `actionables.html` | The entire app. Open locally or host anywhere (e.g. Hostinger). |
| `setup_fets_actionables.sql` | One-time database setup — paste into Supabase SQL Editor and Run. |
| `patch_fets_os.sql` | Adds the FETS OS Centre Rollout tables (`centres`, `centre_rollout`) — run once. |
| `patch_delete_policy.sql` | Only if your DB was created with an older setup script. |
| `PROJECT_CONTEXT.md` | **Full project memory.** Read this first — new developers AND Claude sessions. |

## Quick start

1. Supabase project → SQL Editor → run `setup_fets_actionables.sql` (once).
2. SQL Editor → run `patch_fets_os.sql` (once) — enables the Centre Rollout board.
3. Open `actionables.html` (or upload to your host) — dashboard lights up with ACT-01 & ACT-02.
4. Optional: Chat Alerts page → paste a Google Chat incoming-webhook URL for team notifications.

## Continuing work with Claude on any computer

Clone this repo, open a Claude (Cowork) session with the repo folder connected, and say:

> "Read PROJECT_CONTEXT.md — let's continue the FETS Actionables project."

⚠️ **Keep this repository PRIVATE** — `actionables.html` embeds the Supabase anon key,
and the database currently has open policies (see Security section in PROJECT_CONTEXT.md).

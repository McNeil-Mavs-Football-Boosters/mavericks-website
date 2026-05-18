# Mavericks Website

Replacement website for [mcneilmavericks.org](https://mcneilmavericks.org) — McNeil Mavericks Football Booster Club. Cutting over from SportsEngine before the 2026-07-31 renewal.

**Status (2026-05-17):** Commit B end-to-end shipped. Every public route in the v2 spec route map renders real data or 404s per spec. McNeil HS official brand identity applied site-wide. Cutover target: July 13–20. See [`docs/CLAUDE.md`](./docs/CLAUDE.md) for the current Status table, build log, and "What's live" inventory. Spec docs are in [`docs/specs/`](./docs/specs/) (read order is in `docs/CLAUDE.md` → "Docs (canonical for v2)").

## Stack

- **Framework**: Next.js 16 (App Router) + TypeScript (strict)
- **Styling**: Tailwind CSS v4 + shadcn/ui (base-nova). Brand tokens (`--mavs-navy #011858`, `--mavs-green #1E541E`, `--mavs-brown #7C5838`) in `app/globals.css`.
- **Type**: Lato (Google Fonts) via `next/font/google` — weights 400/700/900
- **Backend**: Supabase (Postgres + Auth + Storage + RLS)
- **Payments**: Stripe Checkout (guest checkout, no public user accounts)
- **Email**: Cloudflare Email Routing (Phase 1); Resend deferred to Phase 2
- **Hosting**: Vercel (auto-deploy from `main`)
- **Tooling**: ESLint (next + prettier compat), Prettier (+ tailwind plugin)

## Local setup

```bash
npm install
cp .env.example .env.local   # fill in Supabase + Stripe keys
npm run dev                  # http://localhost:3000
```

Scripts:

| Command                | What it does                             |
| ---------------------- | ---------------------------------------- |
| `npm run dev`          | Start the dev server on :3000            |
| `npm run build`        | Production build                         |
| `npm run start`        | Run the production build locally         |
| `npm run lint`         | ESLint                                   |
| `npm run lint:fix`     | ESLint with `--fix`                      |
| `npm run format`       | Prettier write across the repo           |
| `npm run format:check` | Prettier check (no writes)               |
| `npm run typecheck`    | `tsc --noEmit` against the whole project |

## Environment variables

All env vars are listed in [`.env.example`](./.env.example). Copy that file to `.env.local` for local dev and populate values from:

- **Supabase** → Project Settings → API (URL, anon key, service role key)
- **Stripe** → Developers → API keys (test mode until Step 15); webhook signing secret from the webhook endpoint config
- **Resend** → API Keys (Phase 2 only; leave blank for now)

In Vercel, set the same vars under Project Settings → Environment Variables. Use separate values for Preview vs Production (especially Stripe — test keys in Preview, live keys in Production).

Anything prefixed with `NEXT_PUBLIC_` is exposed to the browser bundle. `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, and `RESEND_API_KEY` are server-only — never reference them from client components.

## Folder layout

```
app/
  (public)/    public-facing routes (home, about, news, events, sponsors, ...)
  (admin)/     admin shell + CRUD pages (auth-gated)
  api/         API routes (Stripe webhook, contact form, membership create, ...)
components/
  ui/          shadcn/ui primitives
lib/
  supabase/    server + browser Supabase clients
db/
  migrations/  ordered SQL migration files (001_*.sql, 002_*.sql, ...)
  seed/        seed data (membership tiers, sponsorship tiers, board, committees)
```

## Database migrations

All schema changes live in `db/migrations/`, numbered sequentially. Files are applied in numeric order. `db/apply_all.sql` is a concatenated bundle of every migration through the latest, for fresh-DB rebuilds via Supabase SQL Editor (regenerate after every new migration — recipe at the bottom of `docs/CLAUDE.md`). Migration sequence as of 2026-05-17: 001 through 033.

### Apply a single migration

Requires `psql` on PATH (`brew install libpq && brew link --force libpq` on macOS) and `SUPABASE_DB_URL` set in `.env.local` (the Session pooler URI from Supabase → Connect, with the DB password substituted in and any `&` URL-encoded as `%26`).

```bash
set -a && source .env.local && set +a
psql "$SUPABASE_DB_URL" -f db/migrations/0XX_name.sql
```

### Rebuild from scratch

```bash
set -a && source .env.local && set +a
psql "$SUPABASE_DB_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
psql "$SUPABASE_DB_URL" -f db/apply_all.sql
```

Storage buckets are not created by SQL — they must be set up via Supabase Studio (see next section).

### Verification queries

Each migration in this project was applied with a paired verification query. The verify pattern is documented in commit messages on `main`.

## Supabase Storage buckets

Buckets are created manually in Supabase Studio (Storage → New bucket). Each image bucket should be configured as:

- Public bucket: on
- Restrict file size: 5 MB
- Restrict MIME types: `image/png, image/jpeg, image/webp`

Current buckets:

| Bucket | Size limit | MIME types | RLS policies migration |
|---|---|---|---|
| `news-images` | 10 MB | `image/png, image/jpeg, image/webp` | `009_storage_policies.sql` |
| `event-images` | 10 MB | `image/png, image/jpeg, image/webp` | `009_storage_policies.sql` |
| `sponsor-logos` | 10 MB | `image/png, image/jpeg, image/webp` | `009_storage_policies.sql` |
| `board-photos` | 5 MB | `image/png, image/jpeg, image/webp` | `009_storage_policies.sql` |
| `coach-photos` | 5 MB | `image/png, image/jpeg, image/webp` | `026_coach_photos_storage_policies.sql` |
| `site-images` | 10 MB | `image/png, image/jpeg, image/webp` | `009_storage_policies.sql` |
| `documents` | 50 MB | Any | `009_storage_policies.sql` |

RLS policies on `storage.objects` are SQL-managed via migrations. Bucket settings (public, size, MIME) are Studio-managed.

## Build plan

The full 20-step Phase 1 plan is in [`docs/specs/build_plan_v2.md`](./docs/specs/build_plan_v2.md). Current state: Steps 1–4 done, 4b done, 4c (Commit A + Commit B in full) done. Step 5 onward pending. See `docs/CLAUDE.md` for the live status table and most recent build progress.

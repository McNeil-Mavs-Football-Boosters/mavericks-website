# MavericksWebsite — Project Guide

Replacement website for `mcneilmavericks.org`. **The site is the McNeil Mavericks football public website, run by the McNeil Maverick Football Booster Club** — booster CRM (memberships, sponsorships, donations, board) is nested under `/boosters` rather than being the whole site. This framing changed mid-build (see "The pivot" below).

Booster club running info (officer roster, meeting cadence, contact info) lives at `~/Projects/BoosterClub/`.

## Reaching Jeremy mid-task

When you need Jeremy's input or sign-off to proceed, use **`jv-ask`** — not `jv-notify`. They look similar but behave very differently:

- **`jv-ask -s "claude-code (mavs-website)" "<question>"`** — blocks for up to 20 min; prints Jeremy's Slack reply to stdout (exit 0) or exits 2 on timeout. **Use this whenever your next step depends on his answer.** Examples: "ok to apply migration X?", "verify the staging page and reply 'go' for Part 2", "should I revert the flag?". Read the stdout and act on it. On exit 2 (timeout), stop or pick a conservative default — don't assume yes.
- **`jv-notify -s "claude-code (mavs-website)" "<update>"`** — fire-and-forget. Use only for status updates that don't need a reply ("Part 1 shipped, moving to Part 2", "DB rotated, done"). If you append "reply X for next step" to a notify, Jeremy can't actually relay back — Slack has no channel to reach you. That phrasing implies `jv-ask`.

Rule of thumb: if you're going to wait, use `jv-ask`. If you're moving on regardless, use `jv-notify`.

**Why this matters for steering:** between `jv-notify` checkpoints you are *unsteerable from Slack*. Jeremy's Slack replies have no return path to you — they go to the JV Assistant bot's normal Claude handler, which has no idea you exist. If Jeremy needs to stop or redirect you mid-task, he has to type in this CLI window directly. So:

- **If a checkpoint genuinely needs Jeremy's input before you proceed, use `jv-ask`.** That's the only way Slack can steer you.
- **If you `jv-notify` "Part N done" and then immediately start Part N+1, you've removed Jeremy's ability to say "wait, hold on" from his phone.** Don't chain phases through notify if you wouldn't be comfortable with the next phase shipping without his review.
- Phrases like "reply 'go' for next part" or "let me know if you want changes" in a `jv-notify` are a red flag — those are `jv-ask` situations.

## Status (2026-05-17)

**Steps 1–4c Commit B slices 1–3 + freshman-designation fix shipped.** Schedule routes are in (empty-state for games, markdown/empty-state for practice). Cutover target: July 13–20 with fallback to July 27. SE renewal lapses 2026-07-31.

| Step | Status | Notes |
|---|---|---|
| 1. Scaffold | ✅ done | Next.js 16.2.6 + TS strict + Tailwind v4 + shadcn/ui (base-nova) |
| 2. Supabase wiring | ✅ done | `lib/supabase/{server,client}.ts` |
| 3. Schema applied (v1) | ✅ done | 10 migrations under `mavericks-website/db/migrations/` |
| 4. Public layout + 5 static routes | ✅ done | shipped before the pivot; superseded by 4b for header/home/about |
| 4b. Football-first IA reshape | ✅ done | commit `58b6577`. Header, home, /boosters, /about, /contact rewritten |
| **4c Commit A. Apply schema v2 migrations** | ✅ done | migrations 011-026; `3eb95c1` through `ff9feaf` |
| **4c Commit B slice 1. Schedule layout + games/[level] + Game/Practice toggle** | ✅ done | `aa2fa0b` |
| **4c Commit B slice 2. Practice routes** | ✅ done | `de846d5`. react-markdown + remark-gfm for practice body |
| **4c Commit B slice 3. Freshman games designation route** | ✅ done | `7bf7ec3` |
| **4c Commit B fix. Designation conditional on `freshman_has_blue`** | ✅ done | `b5dd67b` games-page; `2422f0f` practice-page "Green & Blue" + spec § 5 paragraph |
| 4c Commit B next. Games table render (replace empty state with `games` query) | ⏳ pending | needs seed game rows; nothing in `games` table yet |
| Deliverable C. Roster routes (`/roster`, `/roster/[level]`, `/roster/freshman/[designation]`) | ⏳ pending | spec § 6 |
| Deliverable D. Coaches (`/coaches`) | ⏳ pending | spec § 7 |
| Deliverable E. Resources (`/resources`) | ⏳ pending | spec § 8 |
| Print stylesheets (schedule + roster) | ⏳ pending | spec § 9 "Print" |
| 5. Public collection routes (expanded) | pending | news/sponsors + /boosters/* |
| 6–20 | pending | See `specs/build_plan_v2.md` |

**Staging URL** (no SSO wall as of Step 4b push): `https://mavericks-website-jeremy-vest-s-projects.vercel.app`. Stable alias; per-deployment URLs follow the `mavericks-website-<hash>-jeremy-vest-s-projects.vercel.app` pattern. Per the prior CLAUDE.md, Deployment Protection was set to ON — Step 4b smoke tests returned 200 across the board, so the protection may have been disabled at some point. Re-check before assuming.

**Pre-Step-4b decisions locked** (no longer open):
- Rich text editor: **TipTap**
- Staging URL strategy: **point `mcneilmavericks.com` (existing Network Solutions WebForwarder) at Vercel** during the build for friendlier demo URLs (DNS work pending Jeremy)
- Invite officers to admin during **Step 6** as each is available, not in a single ceremony at the July 7 meeting

## Build progress 2026-05-16 (end of session)

- Step 4c Commit A shipped. Migrations 011-026 applied, committed, pushed.
- 20 tables in public schema (13 original + 7 new). RLS on all new tables.
- Storage: 7 buckets, image buckets restricted to png/jpeg/webp, sizes per spec.
- Seed: rosters stubs, Wallin + Hale on coaches, 6 resource_links, practice schedule stubs, mailing_address, freshman_has_blue=false.
- followups.md created and maintained (18 open items including: rotate Supabase anon and service_role keys; investigate news-images Studio policy anomaly; verify Kelly Reeves address; SE Tier 1 capture; mobile QA pass; seed 2025 varsity game results for June 2 board demo).
- Next: Step 4c Commit B — current_year code swap + new public routes for /schedule, /roster, /coaches, /resources. No admin CRUD yet. Estimated 2-3 evenings.

## Build progress 2026-05-17 (end of session)

- Commit B slices 1-3 + designation fix shipped. Every `/schedule/*` URL in spec § 5 route map now renders or 404s per spec, except the actual games table render (empty-state card for now).
- Files added: `app/schedule/layout.tsx` (server, renders Game/Practice toggle + children); `components/schedule/game-practice-toggle.tsx` (client, `usePathname`-driven, drops freshman designation on Practice link per spec § 5 line 202); `app/schedule/games/[level]/page.tsx` (varsity/jv); `app/schedule/games/[level]/[designation]/page.tsx` (freshman; reads `freshman_has_blue` to gate blue + omit designation from copy when flag is false); `app/schedule/practice/[level]/page.tsx` (varsity/jv/freshman, markdown body or empty-state); `app/schedule/practice/[level]/[catchall]/page.tsx` (404).
- Deps added: `react-markdown`, `remark-gfm` for runtime markdown render.
- Spec edits to `commit_b_spec_v2.md` § 5 (no version bump, in-place clarifications): "Freshman designation in user-facing copy" paragraph (game pages); "Freshman practice title when `freshman_has_blue = true`" paragraph (practice title = "Freshman Green & Blue Practice Schedule" when flag is on).
- Manual `freshman_has_blue` toggle acceptance test ran via psql, blue=true verified end-to-end (titles flipped, /freshman/blue 200d), reverted to false.
- Next: games table render — seed `games` rows for 2026-27 (need a roster decision: real data vs scrimmage stubs?), then replace empty-state cards with a real table. Or jump to roster routes (Deliverable C). Or coaches (Deliverable D). Or resources (Deliverable E). All four are independent.

## The pivot (2026-05-16)

Jeremy clarified mid-build that the site's audience is the McNeil football community, not the booster club's members specifically. The current SE site is the football team's de facto public web presence; the booster club just owns the hosting. Reframe:

- IA: football-first nav (Schedule, Roster, Coaches, News, Sponsors, Forms & Links), with all booster CRUD nested under `/boosters`.
- Home page leads with hero + Next Game + Quick Links + News + Events + Sponsors strip (Stony Point's `stpfootball.org` is the IA reference).
- Schedule is admin-maintained (12-14 games/season); **MaxPreps is the public-facing link for live scores** but never auto-synced.
- Head coach situation is sensitive: Jonathan Cruz was hired March 2026, arrested May 2026 on a child-abuse charge predating his McNeil hire, now on administrative leave. **No head coach name at launch.** Coaches page handles "Head Coach: position currently open" gracefully.
- Freshman team can split into Green (default) and Blue (optional) — controlled by `site_settings.freshman_has_blue` flag in schema v2. Freshman URLs always carry a designation: `/schedule/games/freshman/green` (no `/schedule/games/freshman`).

The v2 docs (`specs/*_v2.md` + addenda) supersede the originals for spec questions.

## Docs (canonical for v2)

Spec docs evolve as a chain of addenda rather than rewrites. Read in order if you're picking up cold:

1. **`specs/site_pivot.md`** — Why the IA changed; existing-site inventory; comparable analysis (Stony Point).
2. **`specs/site_pivot_addendum.md`** — MaxPreps as schedule data source; Cruz situation; SE Tier 1 capture checklist.
3. **`specs/schema_v2.md`** — New tables: games, rosters, coaches, resource_links + site_settings additions.
4. **`specs/schema_v2_addendum.md`** — `players` table with jersey/position/grade structured fields; coach photo bucket; SportsYou seed fix.
5. **`specs/schema_content_v2_addendum2.md`** — `sponsorship_inquiries`; `team_designation` column on games/rosters; `practice_schedules`; URL split by team level; footer social additions.
6. **`specs/schema_content_v2_addendum3.md`** — Freshman URLs always have designation; `freshman_has_blue` admin flag; practice shared between Green/Blue (no designation on practice URLs).
7. **`specs/content_map_v2.md`** — Every public route, sections, data sources.
8. **`specs/admin_scope_v2.md`** — Three admin roles, permission matrix, admin pages (Tier A/B/C), workflows.
9. **`specs/build_plan_v2.md`** — Implementation plan; supersedes the original `build_plan.md`. Step ordering, hard dates, time budget.

**Older docs (v1)** still useful as reference but no longer the source of truth:
- `specs/content_map.md` — booster-focused IA (pre-pivot)
- `specs/admin_scope.md` — original admin spec
- `specs/schema.md` — v1 schema (13 original tables; tables themselves unchanged, just extended in v2)
- `specs/build_plan.md` — original 20-step plan
- `spec_review.md` — resolution log; still useful for "why is X the way it is?"

**Project meta-docs (outside the repo, at the `MavericksWebsite/` parent directory):** `../../dns_audit.md`, `../../credentials.md`, `../../next_steps.md`, `../../sportsengine_capture.md`, `../../dns_raw/`. Kept outside git because `credentials.md` is sensitive and the rest are local-only reference data.

## Stack

- **Frontend**: Next.js **16.2.6** (App Router) + TypeScript (strict + `noUncheckedIndexedAccess`) + Tailwind v4 + shadcn/ui (`base-nova` style on `@base-ui/react`)
- **Hosting**: Vercel (auto-deploy from `main`)
- **Backend**: Supabase (Postgres + Auth + Storage + RLS)
- **Payments**: Stripe Checkout (guest checkout — no public user accounts)
- **Email**: Cloudflare Email Routing for role aliases (pending); Resend for contact-form delivery (wired in Step 4)
- **Repo**: GitHub org `github.com/McNeil-Mavs-Football-Boosters/mavericks-website` (public)

**Components installed in `mavericks-website/`:**
- shadcn primitives: `button`, `input`, `label`, `textarea`
- React deps: `react-hook-form`, `@hookform/resolvers`, `zod`, `resend`, `@next/mdx`, `@mdx-js/loader`, `@mdx-js/react`, `lucide-react`
- **Lucide v1.x dropped brand glyphs** (trademark reasons). Inline SVGs in `components/layout/Footer.tsx` provide Facebook/Instagram/Youtube icons. If we add X/Twitter (anticipated in schema v2), keep inlining or add a brand-icon dep.

## What's live as of Commit B slice 3 + fix (`2422f0f`)

Adds to the Step 4b inventory below:

- `/schedule` → 308 redirect to `/schedule/games/varsity`.
- `/schedule/games/varsity`, `/schedule/games/jv` — page header (title + "Live scores and stats →" MaxPreps subhead) + Game/Practice pill toggle + empty-state card with MaxPreps button. No `games` query yet.
- `/schedule/games/freshman/green` — empty-state card. Title and copy include "Green" only when `site_settings.freshman_has_blue = true`; just "Freshman" when false. Matches header dropdown convention.
- `/schedule/games/freshman/blue` — 200 only when `freshman_has_blue = true`, else 404.
- `/schedule/games/varsity/*`, `/schedule/games/jv/*`, `/schedule/games/freshman/anything-else` — 404.
- `/schedule/practice/varsity`, `/schedule/practice/jv`, `/schedule/practice/freshman` — queries `practice_schedules` for current year + level + active. Renders markdown body when non-empty, `source_note` in empty-state card otherwise. Freshman practice title becomes "Freshman Green & Blue Practice Schedule" when `freshman_has_blue = true`; plain "Freshman" otherwise.
- `/schedule/practice/*/anything` — 404.

**Schedule layout** (`app/schedule/layout.tsx`) is a server component that primes `getSiteSettingsCore()` and renders the `<GamePracticeToggle>` above `{children}`. The toggle is a client component using `usePathname()`; on freshman game pages the Game button always links to `/schedule/games/freshman/green` (drops the designation per spec § 5 line 202 for the Practice link). On `notFound()` inside `/schedule/*`, the schedule layout is unmounted and the root layout's `not-found.tsx` is rendered — header and footer still appear, but the toggle does not. Not a spec requirement to fix; revisit if it becomes a UX issue.

## What's live as of Step 4b (commit 58b6577)

**Public routes:**
- `/` — football homepage. Hero (defaults to "McNeil Mavericks Football" / "Home of the McNeil Mavericks · Austin, TX" / "Join the Booster Club" → `/boosters/join`). Quick Links band (6 lucide-icon cards: Join, Sponsor, Donate, Volunteer, Schedule, Roster). Latest News, Upcoming Events, Sponsors strip — each section **hides entirely** when its query returns zero rows. Next Game card removed entirely until `games` table exists (Step 4c+).
- `/about` — short "about the site" page with embedded `ContactForm`, direct-contacts list, disclaimer. NOT the booster club page.
- `/boosters` — booster club landing. Mission blockquote, "What dues fund" placeholder (JSX comment preserved: `{/* PLACEHOLDER — replace once Chevon delivers copy */}`), 4-card Quick Actions grid, 2026-27 board grid (queries `board_members`), affiliations & contact (mailing address pulled from DB), section nav.
- `/contact` — `permanentRedirect("/about")` (308). Legacy URL; the form moved.
- `/privacy` — MDX route rendering `content/privacy.mdx` (placeholder body).
- `/404` (app/not-found.tsx) — heading + 3 nav links (Home / About / Contact). Note: links to "Contact" — left as-is; redirects to /about anyway.
- `/api/contact` — POST handler. Zod-validated. Honeypot returns 400. Resend send; logs errors, returns generic 500 on failure.

**Header / layout:**
- 9-item desktop nav at `lg:` breakpoint (1024px). Tablet (`md:` to `lg:`) uses the hamburger drawer.
- Order: Home, Schedule, Roster, Coaches & Trainers, News, Sponsors, Forms & Links, Boosters ▼, About.
- Boosters dropdown is **click-only** (no hover). Outside-click and Escape close it. Chevron rotates 180° when open. Conditional render — panel HTML not in initial SSR; only the trigger is.
- Mobile drawer mirrors the 9 items with Boosters as an accordion.
- Wordmark: "McNeil Mavericks Football" / "Mavs Football" on mobile.

**Footer:**
- 3-column desktop, stacked mobile. Column 1: display_name + tagline + `<address>` (only renders if `mailing_address` not null).
- Column 2 (Site links): Home, Schedule, Boosters, Sponsors, Donate, About, Privacy.
- Column 3: mailto + inline-SVG social icons (Facebook, Instagram, Youtube) — each hides when its corresponding URL is null in `site_settings`.
- Full-width school-affiliation disclaimer from `site_settings.school_affiliation_disclaimer`. Copyright row hardcoded.

**Site settings (DB state):**
- `site_settings.mailing_address` is **seeded directly in Supabase** as `"#412, 6001 W Parmer Ln, Suite 370\nAustin, TX 78727"`. This was done via service-role one-shot, **not via a migration**. **Step 4c todo:** add a migration so a fresh DB setup gets this value.

## Open follow-ups for Step 4c

These are not blockers but will need attention as Step 4c progresses:

1. ✅ **Done** (commit `b46f63c`). **`facebook_group_url` → `facebook_boosters_url` rename** applied via migration 023 with matching edits in `Footer.tsx` and `lib/types.ts`.
2. **Hardcoded `'2026-27'`** in three queries: home page Sponsors strip, `/about` board (no longer relevant — board moved to /boosters), `/boosters` board grid. Replace with `site_settings.current_year` after that column is added. **Deferred to Commit B.**
3. ✅ **Done** (commit `9e6916a`). **`mailing_address` migration** captured in 025; idempotent UPDATE preserves the live two-line value and reproduces it on fresh-DB rebuilds.
4. ✅ **Done** (commit `ba1d200`). **`coach-photos` Storage bucket** created in Studio (5 MB, image/png + image/jpeg + image/webp); storage policies added via migration 026; README Storage bucket inventory documents the full 7-bucket state.
5. **Resend env vars in Vercel** still need to be set for the contact form to actually send: `RESEND_API_KEY`, `CONTACT_TO_EMAIL`, `CONTACT_FROM_EMAIL`. Until then, /api/contact returns 500 "Email not configured" on valid submissions.

## Operational facts (unchanged from Step 4)

- **GitHub repo**: `github.com/McNeil-Mavs-Football-Boosters/mavericks-website`. Default branch `main`. Public.
- **GitHub auth**: gh CLI has two accounts. **Push as `jeremyvest-ATXcoder`**, NOT `jvest-s3`. `gh auth switch -u jeremyvest-ATXcoder` if needed.
- **Vercel project**: `jeremy-vest-s-projects/mavericks-website`. Auto-deploy from `main`. Stable URL: `mavericks-website-jeremy-vest-s-projects.vercel.app`.
- **Supabase project**: ref `rgdoolafpvhtsdpxbqvj`, US region. URL `https://rgdoolafpvhtsdpxbqvj.supabase.co` (bare; JS client appends `/rest/v1/`).
- **Storage buckets (all public, 7 live)**: `board-photos`, `coach-photos`, `documents`, `event-images`, `news-images`, `site-images`, `sponsor-logos`. Image buckets restricted to png/jpeg/webp; see `mavericks-website/README.md` for per-bucket size/MIME inventory.
- **Env vars** (in `.env.local` and Vercel):
  - `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
  - `RESEND_API_KEY`, `CONTACT_TO_EMAIL`, `CONTACT_FROM_EMAIL` (default `onboarding@resend.dev`)
  - Future: `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `NEXT_PUBLIC_SITE_URL`
- **Service-role JWT was pasted in chat history during Step 2**. Rotate via Supabase → Project Settings → API → Reset; update `.env.local` and Vercel env vars when convenient.

## Key facts

- **Domain**: mcneilmavericks.org (Network Solutions, expires 2028-08-16, transfer-locked, privacy-proxied). Also own `mcneilmavericks.com`.
- **Existing site**: SportsEngine site ID 21475, "Itasca" theme, behind Cloudflare. News last updated 2018.
- **SE renewal lapse**: 2026-07-31. Hard deadline: cancel by 2026-07-29 or accept another $1,385.
- **Email today**: GoDaddy MX. Migrating to Cloudflare Email Routing aliases (J9).
- **Nonprofit**: 501(c)(3), EIN **26-4231242**, legal name "McNeil Maverick Football Booster Club". Eligible for Stripe nonprofit pricing.
- **Phase 1 admin roles**: `super_admin`, `content_admin`, `readonly_admin` (Chevon as treasurer). Per admin_scope_v2: Jeremy + Carol are super_admin (plus institutional `president@`/`webmaster@` recovery accounts in Step 6).
- **Mailing address**: `#412, 6001 W Parmer Ln, Suite 370, Austin TX 78727` (PO Box-style, from existing /boosters page; confirmed live-seeded in DB).
- **Head coach situation**: Cruz hired March 2026, arrested May 2026, on admin leave. **Launch with no head coach listed.**

## Cross-references

- Booster club running info: `~/Projects/BoosterClub/booster_club_info.md` — officers, roles, contacts.
- Booster club auto-memory: `booster_club.md` (in `~/.claude/projects/-Users-jvest/memory/`).
- Project-overview index: `~/Projects/CLAUDE.md`.

## Working notes for future sessions

- **Read order for a fresh session**: this file → `specs/build_plan_v2.md` (current step) → the v2 spec docs in order (`site_pivot.md` → `site_pivot_addendum.md` → `schema_v2.md` → addenda → `content_map_v2.md` → `admin_scope_v2.md`) only as needed → `spec_review.md` for "why" questions.
- **Before coding any next step**: check `mavericks-website/AGENTS.md`'s warning. Next.js 16 has breaking changes from v15; consult `node_modules/next/dist/docs/` for the relevant subsystem.
- **The Boosters dropdown panel is conditionally rendered** (client-state-driven), so its 10 sub-links aren't in initial SSR HTML. Modern Googlebot is fine; the static Footer Column 2 covers discoverability for non-JS crawlers via direct `/boosters` link.
- **Schema gaps caught during Step 3** (still not in `spec_review.md` — add when convenient):
  - `schema.md` only granted EXECUTE on `current_user_has_role()` and SELECT on `public_members`. Missing all base table grants. Fixed at top of `db/migrations/008_rls.sql`.
  - `service_role` bypasses RLS at the role level (BYPASSRLS) but PostgREST still requires base table privileges. Easy to miss — Supabase's table UI auto-grants this.
- **Applying further migrations / running ad-hoc queries**: `psql` is on PATH (libpq via brew). Apply migrations or run one-off SQL via:
  ```
  set -a && source .env.local && set +a
  psql "$SUPABASE_DB_URL" -f db/migrations/0XX_name.sql
  ```
  `SUPABASE_DB_URL` is the Session pooler URI from Supabase Connect, with the password URL-encoded (`&` → `%26`, etc.). **Never echo `$SUPABASE_DB_URL`.** `db/apply_all.sql` remains as the concatenated bundle for one-paste via Supabase SQL Editor when psql is not handy; after any migration edit, regenerate via `for f in db/migrations/0*.sql; do printf '\n-- ===\n-- %s\n-- ===\n\n' "$f"; cat "$f"; done > db/apply_all.sql`.
- **Stripe should be created last** in the new-account chain so receipts come from a real `treasurer@mcneilmavericks.org` role address.
- **Migration of 35 existing Google Form signups**: 7 paid rows should go to `payments` with `method = 'other'`, NOT `'stripe'`. See schema.md migration plan and Step 12 of build_plan_v2.md.

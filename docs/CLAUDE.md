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

## Status (2026-05-19 — Hero carousel + Print View PDFs live; Wallin updated)

**Commit B fully shipped end-to-end** (2026-05-17). **Booster Phase 1 slices 1 + 2 shipped on top** (2026-05-18 and 2026-05-19). **Homepage HeroCarousel + canonical-PDF Print View links shipped end-to-end** in the late-day 2026-05-19 session. Every public route in the v2 spec route map renders real data or 404s per spec. The old `window.print()` "Print" buttons on roster/schedule pages have been **replaced** with "Print View" links to the official PDFs (the same handouts parents get at meetings); practice schedules no longer have any print affordance — browser Cmd-P only. McNeil HS official brand identity applied site-wide (navy primary, Lato type). Year fields split into `current_year` (football) and `current_board_year` (board), decoupled. Cutover target: July 13–20 with fallback to July 27. SE renewal lapses 2026-07-31.

**Phase 1 pivot for boosters** (2026-05-18): the original `/boosters/join` Stripe-Checkout flow was scoped out for Phase 1. Replaced with a Google-Form CTA + server-rendered tier ladder. `/boosters/members` is now backed by the Form-responses sheet (read-only service account) rather than the `public_members` view. The Stripe + custom-form / `public_members` view design lives on as Phase 2+ work; see `specs/boosters_join_spec.md` and the "Phase 1 reality" notes appended to `specs/content_map_v2.md` /boosters/join + /boosters/members sections.

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
| **4c Commit B slice 4 Parts 1–3 + fixes. Games table + print** | ✅ done | `26c6322` → `9d32ada` (seed 027 + render + print + 028 real URLs + spec clarification) |
| **4c Commit B Deliverable E. `/resources`** | ✅ done | `32400b1`. resource_links grouped by section, icon mapping, empty state, /resources/[catchall] → 404 |
| **4c Commit B Deliverable C. `/roster/*`** | ✅ done | `a7a9aa8`. Layout + varsity/jv + freshman/[designation] + PlayerTable + 27-player test seed (migration 029) |
| **Year split — `current_year` + `current_board_year`** | ✅ done | `8971644`. Migration 030 (schema add + relabel football data 2026-27 → 2025-26); board untouched at 2026-27; `app/boosters/page.tsx` reads `current_board_year` |
| **Real 2025-26 roster + schedule seed** | ✅ done | `e7ae151` + `947ed46`. Migrations 031 (JV=65, F-Green=22, F-Blue=27, freshman_has_blue=true) + 032 (real 2025 schedule, 46 games) + 033 (8 freshman color-resolved by Jeremy) |
| **4c Commit B Deliverable D. `/coaches`** | ✅ done | `6d2e082`. Section grouping by `role_category`, CoachCard with default-avatar fallback, head-coach-open placeholder, /coaches/[catchall] → 404 |
| **Brand pass — McNeil HS style guide** | ✅ done | `2ac698c`, 28 files. Navy (#011858) primary, green (#1E541E recolored darker) secondary, brown (#7C5838) tertiary token. Lato (Google Fonts 400/700/900) replaces Geist. Logo + favicon installed. |
| **Booster Phase 1 slice 1 — `/boosters/join` (Form CTA tier ladder)** | ✅ done | `9837aba` (migration 034 reseed) + `090986f` (page + footer link + `lib/constants.ts`) + `9185b4b` (solid-navy unbadged borders, orphan-card centering). Replaces the original Step 6 Stripe-Checkout join flow; see `specs/boosters_join_spec.md`. |
| **Booster Phase 1 — Google Sheets API setup** | ✅ done | `8b79407` (add) + `3030f2a` (remove smoke test). GCP project `mcneil-mavericks-site` under `mcneilfootballboosters@gmail.com`, service account `mcneil-site-reader@…`, sheet shared at Viewer, `googleapis@^171.4.0` installed, 3 env vars wired in `.env.local` + Vercel (Production+Preview+Development). JSON key at `~/Projects/BoosterClub/MavericksWebsite/secrets/mcneil-site-reader.json`, outside the repo. |
| **Booster Phase 1 slice 2 — `/boosters/members` (Sheets-backed list + Top Donors)** | ✅ done | `92239e3` (initial slice) + `5bea309` (polish pass — 8-item rewrite) + `563955b` (Top Donors green band + centered names). ISR `revalidate=300`. `lib/sheets/boosters.ts` does JWT auth + dedupe (email primary, parent1-name fallback, latest-timestamp wins). Flat alphabetical-by-surname list in Lato Black uppercase navy; Top Donors section on mavs-green band with dynamic 1/2/3-col grid. |
| **Header/footer nav restructure** | ✅ done | `afee45f`. Removed "Home" from desktop + mobile + footer center column. Top-level "Boosters" header label renamed to "Booster Club" (label only — routes/dropdown-children/titles unchanged). Booster Club moved to position immediately after Coaches & Trainers. About moved out of the header entirely; added to footer right column below the contact-email line. Header inner content constrained to `lg:max-w-[80vw] lg:mx-auto` (band stays full-width; content centered at 80% viewport at lg+). |
| **Homepage Hero Carousel — full 3-turn rollout** | ✅ done | `279f47a` (mig 036 tables + 3 headline_cta seed) + `0cd6c51` (StaticHero extract, mounted on /boosters) + `4ef9154` (mig 037 six bg image seeds) + `6944994` (apply_all.sql regen pattern doc fix) + `efe2113` (HeroCarousel client component + next.config.ts images.remotePatterns) + `8b35446` (object-top crop + +10% section height). Spec: `specs/commit_homepage_hero_carousel_spec.md`. |
| **Print View PDFs + Coach Wallin update** | ✅ done | `c919aa3` (mig 038 documents bucket config + pdf_storage_path/schedule_pdf_storage_path on rosters + PrintViewLink component + 5-page swap + PrintButton/PrintFooter deletion) + `cd27abb` (mig 039 Wallin → Douglas Wallin, Defensive Line Coach) + `4705b8b` (mig 040 freshmen plural path fix). Spec: `specs/commit_print_view_pdfs_spec.md`. |
| **Freshman → Freshmen UI rename** | ✅ done | `a27a08c`. Every user-visible "Freshman" label flipped to "Freshmen" (collective noun). DB enum value `team_level = 'freshman'`, URL slugs `/roster/freshman/{green,blue}`, and code identifiers (`freshman_has_blue`, `FreshmanRosterPage`) deliberately kept singular. |
| 5. Public collection routes (expanded) | in progress | `/boosters/join` + `/boosters/members` live; `news/sponsors` + remaining `/boosters/*` (sponsor, volunteer, committees, board, events, documents, donate) still pending. |
| 6–20 | pending | See `specs/build_plan_v2.md`. Step 6 (admin auth + CRUD) is the next gating item before officers can edit content. |

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

## Build progress 2026-05-17 — slice 4 + Deliverable E (extended session)

Continuation of the same calendar day. Two more bundles shipped after the original 2026-05-17 entry.

**Slice 4 (games table render + print).** Shipped in three parts plus a follow-up batch, with the parallel-subagent pattern (one agent for data/pages, one for components):

- `26c6322` — **Migration 027.** 9 throwaway test rows in `games` for `year='2026-27'`: 5 varsity (W/L/scheduled/cancelled/tbd, one with Homecoming notes, one with watch_url, one with opponent_url + location_url), 2 jv (final win, scheduled), 2 freshman with `team_designation='Green'`. Cleanup path: `DELETE FROM games WHERE year='2026-27';` once admin CRUD lands (Step 7b/13).
- `94ecb6b` — **Part 2 games render.** `lib/queries/games.ts` (`getGamesForTeam({ year, level, designation })` with strict NULL match for varsity/jv and `eq` for freshman Green/Blue, ORDER BY `game_date ASC`); `components/schedule/games-table.tsx` (desktop 7-col, `hidden md:block`, Notes as a colSpan=7 subtitle row, subtle `bg-mavs-green/5` home tint, HOME/AWAY/NEUTRAL badge); `components/schedule/game-card.tsx` (mobile, `block md:hidden`, `space-y-3` wrapper in the page so cards aren't flush); `components/schedule/result-cell.tsx` (W=green, L/T=foreground, em-dash for scheduled, Cancelled/Postponed pill, TBD, defensive em-dash when final but a score is null). Both pages (varsity/jv + freshman) keep the existing title + MaxPreps subhead + freshman designation gating.
- `4ce0afd` — **Part 3 print.** `components/schedule/print-button.tsx` (client, lucide Printer, `print:hidden` self, `window.print()` onClick); `components/schedule/print-footer.tsx` (client, `hidden print:block`, populates `window.location.href` + formatted date on mount). Global `print:hidden` on `<header>` and `<footer>` wrappers and on the `<GamePracticeToggle>` wrapper. `print:block` on the games-table wrapper to force the table at print width regardless of viewport. All tints stripped on print; all colored emphasis → `print:text-black`. Watch icon `print:hidden`. Empty-state copy stays on print (so a no-data page isn't blank) but the empty-state MaxPreps action button is `print:hidden`. Practice markdown body neutralizes link colors via `print:[&_a]:text-black print:[&_a]:no-underline`. `@media print { @page { margin: 0.5in } }` appended to `globals.css`.
- `c2b398a` — **Opponent link new tab.** Both `games-table.tsx` and `game-card.tsx` add `target="_blank"` + `rel="noopener noreferrer"` to the opponent link.
- `14d33c7` — **Migration 028.** Replaces the `roundrockfootball.example.com` placeholder from 027 with the real Round Rock Dragons MaxPreps team page (`https://www.maxpreps.com/tx/round-rock/round-rock-dragons/football/`). Verified via WebSearch. `example_com_urls = 0` across all 9 rows.
- `9d32ada` — **Spec § 5 clarification.** Per-row Opponent bullet now specifies the new-tab behavior and notes the admin convention: `opponent_url` is the opponent's MaxPreps team page; admin label will read "Opponent MaxPreps URL" when CRUD ships.

**Deliverable E `/resources`.** Shipped in one bundle, also via two parallel subagents:

- `32400b1` — `lib/queries/resource-links.ts` (active=true, ORDER BY section, sort_order; logs + returns `[]` on error); `lib/resource-icons.ts` (`iconForHint(hint)` → ExternalLink/FileText/ClipboardList/Play; unknown/null → ExternalLink); `components/resources/resource-section.tsx` (heading + `<ul>` of items; returns `null` for empty links array so empty sections vanish); `components/resources/resource-item.tsx` (icon + `LinkWrapper` that uses `next/link` for `/`-prefixed URLs and a plain `<a target="_blank" rel="noopener noreferrer">` for everything else, per spec § 8); `app/resources/page.tsx` (title "Forms & Links", subhead, groups rows by section in code, renders the five sections in hardcoded enum order, empty-state card with literal `boosters@mcneilmavericks.org`, **`export const dynamic = "force-dynamic"`** because /resources has no params and was prerendering statically — spec § 9 requires per-request render); `app/resources/[catchall]/page.tsx` (unconditional `notFound()`).
- Renders the 6 existing seed rows (Aktivate, UIL, RRISD under Registration & Forms; HUDL, SportsYou under Communications; Kelly Reeves under Stadiums & Directions). Resources + Other sections render no heading because they have zero rows. SportsYou URL is the addendum-corrected `sportsyou.com`, not `#`. Anon role sees all 6 rows (RLS sanity).

**Other notes.**
- The full-context spec read says "force-dynamic is needed when a Commit B page lacks `params`." Worth remembering for Deliverable D (`/coaches`) and any future paramless data page.
- `followups.md` entry on "service-role vs anon-key" expanded 2026-05-17 to enumerate every public read page affected (home, /about, /boosters, /contact, /schedule/games/*, /schedule/practice/*, future /roster, /coaches, /resources). Anon RLS verified directly via psql `SET LOCAL ROLE anon` for both `games` (9 rows) and `resource_links` (6 rows). The wiring fix is deferred to admin work; not blocking Commit B.
- Migration **027 + 028 are throwaway test seeds** for `games`. Admin CRUD will replace them entirely. Cleanup: `DELETE FROM games WHERE year = '2026-27';`.
- Next: Deliverable C (roster) and/or D (coaches). Both independent of each other and of E. Roster also gets print per spec § 9; coaches does not.

## Build progress 2026-05-17 — Commit B close-out + year split + brand pass (final session)

Continuation of the same calendar day. Closed out Commit B end-to-end and shipped the brand identity pass.

**Deliverable C `/roster` (`a7a9aa8`).** `app/roster/layout.tsx` (server, primes `getSiteSettingsCore()`), `app/roster/[level]/page.tsx` (varsity/jv), `app/roster/[level]/[designation]/page.tsx` (freshman/green always, freshman/blue gated on `freshman_has_blue`, omits "Green" from copy when flag is false). `components/roster/player-table.tsx` — desktop 6-col table (`hidden md:block print:block`), mobile stacked cards (`md:hidden print:hidden`), sort_order ASC primary then numeric-aware jersey ASC tiebreaker (the DB's text-sort puts "10" before "2" so the component re-sorts in JS), "—" for null position/grade/height, "{n} lbs" for weight, sr-only caption. `lib/queries/rosters.ts` with `getRosterForTeam` (strict `IS NULL` for varsity/jv, `eq` for freshman Green/Blue) + `getPlayersForRoster`. Reuses `react-markdown`+`remarkGfm` for optional roster `body` preamble. PrintButton + PrintFooter wired identically to schedule. Migration 029 seeded 27 varsity players from the 2025-26 MaxPreps snapshot in `docs/mcneil_varsity_roster_2025-26.txt`.

**Year split — `current_year` vs `current_board_year` (`8971644`).** The /boosters board was queried by `year = current_year`, but Jeremy clarified the operating board is on a different fiscal cadence from the displayed football season (the 2026-27 board governs the 2025-26 football season). Migration 030 added `site_settings.current_board_year text NOT NULL DEFAULT '2026-27'`, flipped `current_year` to `'2025-26'`, and relabeled all football-stamped seed rows (rosters 3, practice_schedules 3, coaches 2, games 9) to `'2025-26'`. `board_members` left untouched at `'2026-27'`. `lib/site-settings.ts` + `lib/types.ts` gained `current_board_year`. `app/boosters/page.tsx:62` and the h2 board heading now read `current_board_year`; local var renamed `currentYear` → `boardYear`. `components/layout/Footer.tsx` `FALLBACK_SETTINGS` gained the field (fallback only fires when the singleton row is missing — never in prod). Idempotent single-tx migration; reversible.

**Real 2025-26 rosters + schedule (`e7ae151` + `947ed46`).** Migration 031: inserted Freshman Blue rosters row, flipped `freshman_has_blue=true`, seeded JV (65 players from `docs/2025 McNeil Football Rosters - JV.pdf`), Freshman Green (19 players, color-read from the PDF), Freshman Blue (22 players, same). 8 freshman players had no Green/Blue color fill in the source — held out, then color-assigned by Jeremy and seeded by migration 033 (Green: #4 Shin, #71 Pelosi, #73 Omagbon; Blue: #19 Brown, #53 Cocke, #55 Solages, #63 Llamas, #72 McCallister). sort_order values picked to tie with each new player's preceding existing player so the PlayerTable's jersey-ascending secondary sort drops them into the right slot without an UPDATE on existing rows. Final freshman counts: Green=22, Blue=27 (49 total, matches the PDF named-row count). Migration 032: DELETE'd the 9 throwaway placeholder games from 027/028, INSERT'd the real 2025 schedule from `docs/2025 Football schedule.pdf` — Varsity=11, JV=11, Freshman Blue=12, Freshman Green=12 (= 46 games). Freshman split-time games are duplicated as Blue (5:00 PM) + Green (6:30 PM) rows; Aug 16 Cedar Park scrimmage and Aug 21 Anderson are mirrored across both teams at the single advertised time. All games `result_status='scheduled'` with NULL scores (2025 season is over but the PDF has no scores — honest representation). All opponent_url/location_url NULL. Notes: 'Homecoming' (V Sep 12 Westwood), 'Senior Night' (V Oct 31 Manor), 'Scrimmage' (F Aug 16 Cedar Park). All times stored as `America/Chicago` timestamptz with correct CDT/CST handling around the Nov 2 DST transition.

**Deliverable D `/coaches` (`6d2e082`).** Single-page server component with `export const dynamic = "force-dynamic"` (paramless DB-reading page, same pattern as /resources). `lib/queries/coaches.ts` returns `Coach[]` ordered by `role_category, sort_order`; the page groups in code into 5 buckets in fixed render order: Head Coach → Coordinators → Position Coaches → Trainers → Staff. Section headings hidden when their bucket is empty, EXCEPT Head Coach when empty — that renders heading + a `HeadCoachPlaceholder` card with the spec's "position currently open" copy. `components/coaches/coach-card.tsx` renders photo (next/image with priority) or default-avatar fallback (filled square in `bg-mavs-green` — picks up navy automatically after the brand pass's token recolor, but the avatar block currently shows the new green; revisit if it should be navy for primary), white initials centered, then h3 name, role, contact links (mailto/tel only if non-null), markdown bio (only if non-empty). `/coaches/[catchall]/page.tsx` unconditional `notFound()`. Hale's role_category was `coordinator` (Defensive Coordinator) so he lands under Coordinators, not Position Coaches — Wallin solo in Position Coaches.

**Brand pass — McNeil HS style guide (`2ac698c`, 28 files).** Decisions: navy as primary (per the official guide), green demoted to semantic-only (W result marker stays `text-mavs-green`), HOME badge + home-game row tint moved to navy. Type: Lato (Google Fonts) replaces Geist site-wide via `next/font/google` weights 400/700/900. h1 = `font-black uppercase tracking-tight`, h2 = `font-bold uppercase`, body = regular (Lato 500 "Medium" is not published by Google Fonts so body uses 400 — captured in `app/layout.tsx` comment + commit message). `app/globals.css` `@theme` block: added `--mavs-navy: #011858`, `--mavs-navy-dark`, `--mavs-brown: #7C5838` (defined, unused — kept available); recolored `--mavs-green: #1E541E` (darker per the guide); shadcn `--primary` now points to `var(--mavs-navy)` so all shadcn primitives adopt navy automatically. Logo: `docs/MHS Logo.png` (official primary lockup) → `public/brand/mhs-logo.png`, rendered in `Header.tsx` via `next/image` at 40×40 with `priority` next to a Lato Black uppercase navy wordmark. Favicon: `docs/MHS Horseshoe Color.jpg` → `app/icon.png` (512) + `app/apple-icon.png` (180); old `favicon.ico` deleted. All green-as-primary refs across header/footer/mobile-nav/Game-Practice toggle/Print button/MaxPreps CTA/dropdown chevrons swapped to navy. Print styles untouched (still `print:text-black` / `print:bg-transparent`).

**Other notes.**
- `lib/supabase/server.ts` still uses the service-role key on every public read — tracked followup, not bundled into any of today's commits.
- All migrations applied locally via psql against the live Supabase project; each verified with a SELECT before commit.
- Style guide PDF + 11 logo source files live in `docs/`. The xlsx with player + guardian PII is gitignored (public repo); should be moved to `MavericksWebsite/private-data/` before cutover.
- Commit B is done. Next session picks from `specs/build_plan_v2.md` Step 5 (news/sponsors/expanded booster routes) or jumps to Step 6 (admin auth + CRUD) if Jeremy wants to start letting officers in.

## Build progress 2026-05-18 — Booster Phase 1 slice 1 + Google Sheets API

Two threads, same calendar day.

**Slice 1: `/boosters/join` Form CTA tier ladder.** Phase 1 pivot: no payments, no custom form. The board-ratified PDF (`docs/2026 - 2027 Membership - McNeil HS Football Boosters.pdf`) defines 7 tiers (Free Fan Base!, Game Day!, Offense ⇄ Defense!, Blitz!, Touchdown!, Playoffs!, Championship!). Single Google Form URL (`BOOSTER_FORM_URL` in `lib/constants.ts`) is the join action across every CTA.

- `9837aba` — **Migration 034 (renumbered from spec's 030 because 030 is taken by the year-split).** DELETE membership_tiers WHERE year='2026-27', INSERT 7 PDF-canonical rows. Idempotent transaction. Verification: count=7, Championship! perks=4, Game Day! badge='Most Popular'. Also committed `docs/specs/boosters_join_spec.md` and the PDF reference.
- `341d57a` — **Spec fix.** All booster references in `boosters_join_spec.md` switched from `current_year` to `current_board_year` (booster year decoupled from football year — 2026-27 vs 2025-26 respectively). Rollback migration reference corrected to 010 (not 018).
- `090986f` — **Slice 1 Turn 2 page.** `app/boosters/join/page.tsx` server component, `force-dynamic`. Green `#1E541E` banner band (one-off brand deviation, documented in top-of-file comment), intro, responsive tier grid (3/2/1 at lg/md/sm), GO MAVS closing block. Each tier card: price+name h3, optional badge pill, tagline, perks with `+ ` prefix, navy "Join at {name}" anchor → `BOOSTER_FORM_URL`, target=_blank, sr-only "(opens in new tab)". `lib/constants.ts` created. `MembershipTier` type added to `lib/types.ts`. Footer SITE_LINKS gained "Join the Booster Club". Followup logged for the missing white-on-transparent horseshoe asset (brand pack doesn't include one; using full-color primary lockup on green as a compromise).
- `9185b4b` — **Polish.** Unbadged cards switched from `border-mavs-navy/10` (barely visible) to solid `border-mavs-navy`. Orphan tier card (last card alone in row at lg or md) centered via modulo detection (`tiers.length % 3 === 1` / `% 2 === 1`), self-heals if active tier count changes.

**Google Sheets API setup (interactive walkthrough).** 9-step setup to wire read-only Form-responses access for slice 2.

- GCP project `mcneil-mavericks-site` created under `mcneilfootballboosters@gmail.com` (club's master Gmail, decoupled from `jvest@s3.com`). Sheets API enabled. Drive API deferred (Sheets-by-ID is enough today).
- Service account: `mcneil-site-reader@mcneil-mavericks-site.iam.gserviceaccount.com`. No project-level IAM roles — sheet-level Viewer share is the only authorization gate. JSON key downloaded, renamed, `chmod 600`'d, and parked at `~/Projects/BoosterClub/MavericksWebsite/secrets/mcneil-site-reader.json` (outside the repo — the repo root is `mavericks-website/`).
- Sheet ID `1-Jyc3dYc6MnMOezGJa4IZpCDINZuxE6zh1QwCLpA7U0`. Title "*USE THIS* McNeil HS Football Booster Club Membership 2026-2027 (Responses)". Two tabs: `Form Responses 1` (live, 33 columns, ~35 row signups at slice-1 build time) and `Sheet1` (empty placeholder).
- Env vars (in `.env.local` and Vercel Production+Preview+Development): `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` (literal-`\n` escaped form; code does `.replace(/\\n/g, '\n')` to normalize), `GOOGLE_SHEETS_BOOSTERS_ID`. Distinct from the existing Supabase anon/service_role rotation followups — do not conflate.
- `8b79407` — added `googleapis@^171.4.0` + throwaway `scripts/test-sheets-access.ts` smoke test (verified Node + JWT + env path works end-to-end; reads metadata + 5 rows of cols A-E).
- `3030f2a` — removed the smoke test in a follow-up commit so it doesn't accrete.

## Build progress 2026-05-19 — Booster Phase 1 slice 2 + nav restructure

**Slice 2: `/boosters/members` Sheets-backed public list.** Initial render → polish pass → Top Donors styling, three commits.

- `92239e3` — **Initial.** `lib/sheets/boosters.ts` (server-only JWT auth, `cache()` memoization, parses tier label + formats parent names as "First L."). `app/boosters/members/page.tsx`, `revalidate=300` (5-min ISR — static prerender + on-demand revalidation, sheet edits propagate within 5 min). Hero band ("{board_year} Boosters" eyebrow + "Our Supporters" h1 + dynamic count). Privacy note line. Tier-grouped list with badge pills + per-tier counts + multi-column names. Bottom "Special Thanks → Top Donors" section with top-3-tier cards on `bg-mavs-navy/5`. CTA back to `/boosters/join`.
- `5bea309` — **Polish pass (8 changes in one commit).** Per Jeremy 2026-05-19:
    1. `h1 = "Members"` (was "Our Supporters").
    2. Main list flattened — no tier groupings/badges. Single alphabetical-by-Parent-1-surname (split on the LAST whitespace, so "Sarah Van Buren" sorts under "Buren").
    3. Each name rendered with the tier-card h3 typography from `/boosters/join` (Lato Black, uppercase, navy). Multi-column responsive grid (1/2/3 cols).
    4. Removed the "Names shown as first name + last initial" line.
    5. Footer block reordered: "Not yet a member? Join the Boosters →" → `BOOSTER_FORM_URL` (Google Form, NOT `/boosters/join`), new tab. "Want yours updated or removed? Email us mcneilfootballboosters@gmail.com" with "Email us" plain text + only the email as a mailto link (the opt-out email is the master Gmail, distinct from `boosters@mcneilmavericks.org` which the Footer uses for general contact — intentional split).
    6. Hero eyebrow `text-white` (was `text-mavs-green`).
    7. Top Donors section: no tier sub-headings, no "go all-in" sentence, same name typography, same surname sort.
    8. **Dedupe in `lib/sheets/boosters.ts`.** Primary key: lowercased Email Address. Fallback when email blank: lowercased Parent 1 Name. Within a key group, latest parseable Timestamp wins. Pre-flight Python scan against live sheet: 35 form rows → 1 with no tier dropped → 2 email-key duplicate pairs collapsed = 32 displayed. Zero same-name-different-email conflicts. Internal `console.warn` logs same-name-different-email conflicts (for future data) without auto-resolving.
- `563955b` — **Top Donors green band + centered names.** Restored "Special Thanks" eyebrow above "Top Donors" h2 (dropped in polish pass by mistake). Section bg → `bg-mavs-green` (`#1E541E`), all text `text-white`. Replaced CSS multi-column layout (which left-aligned names inside columns and pushed N=2 to opposite page edges) with a centered CSS Grid + `text-center`. Grid column count scales with donor count: 1 → `grid-cols-1`, 2 → `grid-cols-1 sm:grid-cols-2`, 3+ → `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`. Container clamped to `max-w-3xl` so sparse N=2 sits near the page center.

**Header/footer nav restructure.** Single commit, 5 changes:

- `afee45f` —
    1. Removed "Home" from header desktop, mobile drawer, AND footer center column. The logo/wordmark already navigates home. The footer-column cascade went beyond Jeremy's literal ask but enforces "no Home in any nav surface".
    2. Renamed top-level "Boosters" header label → "Booster Club" (header only — dropdown child labels/targets, `/boosters` route, page titles, and the footer center-column "Boosters" entry all unchanged per "Header label only").
    3. Reordered desktop + mobile nav so Booster Club sits immediately after Coaches & Trainers. New order: Schedule, Roster, Coaches & Trainers, Booster Club, News, Sponsors, Forms & Links.
    4. Removed "About" from header and from footer center column. Added as a new `<Link>` line in the footer right column, immediately below the `primary_contact_email` mailto line and above the social icons.
    5. Header inner content width constraint at lg+: added `lg:max-w-[80vw] lg:mx-auto` to the header inner div. Header band stays full-width; only the content centers at 80vw with 10% gutters. Note: the desktop nav itself only renders at xl+, so the constraint at lg-xl mainly affects logo/hamburger positioning — benign.

Also: Booster Club dropdown align flipped from `right` to `left` (no longer at the far right of the row).

## Build progress 2026-05-19 (evening) — Hero carousel + Print View PDFs + Wallin + Freshmen

Continuation of the same calendar day, after the morning's slice 2 + nav restructure work. Three threads landed end-to-end.

**Homepage Hero Carousel** (`specs/commit_homepage_hero_carousel_spec.md`). Three-turn rollout in one session.

- `279f47a` — **Turn 1, migration 036_hero_carousel.sql** (renumbered from spec's 035; `035_fix_rrisd_athletic_forms_url.sql` shipped first). Two tables: `hero_background_images` (storage_path/alt_text/sort_order/active) and `hero_foreground_tiles` (tile_type enum `'headline_cta' | 'sponsor_spotlight'` + jsonb payload + sort_order + active). RLS `FOR SELECT TO anon, authenticated USING (active = true)` on both. `touch_updated_at()` triggers. Seeded 3 `headline_cta` tiles (Join / Donate / Volunteer). Background images deliberately not seeded in 036.
- `0cd6c51` — **Turn 2, StaticHero extraction.** `components/shared/StaticHero.tsx` lifted the existing homepage hero JSX verbatim. New shared module `lib/hero.ts` houses `HeroFields` + `HERO_DEFAULTS` + `mergeHero` + a `loadHero()` server fetcher used by both `app/page.tsx` and `app/boosters/page.tsx`. StaticHero mounted as the first child of `/boosters` (full-bleed, OUTSIDE the existing `max-w-5xl` container). Heading order on /boosters now reads: StaticHero h1 → existing page h1 → Our Mission → What dues fund → Get Involved → {boardYear} Board → Affiliations & Contact → Booster Section. Homepage still showed StaticHero between Turn 2 and Turn 3 — replaced in Turn 3.
- `4ef9154` — **Migration 037_seed_hero_backgrounds.sql.** Six rows under `hero/hero-0{1..6}.jpg` with Jeremy-provided alt text. Paired `037_rollback.sql` introduced the **rollback-alongside-migration convention** in `db/migrations/`. The `apply_all.sql` regen incantation grew a `case "$f" in *_rollback.sql) continue;; esac` guard to skip rollback files (a fresh-DB rebuild would otherwise silently re-run the rollback and delete the seed). Docs pattern updated in `6944994`.
- `efe2113` — **Turn 3, HeroCarousel client component.** Built via two parallel subagents (data layer + UI) sharing a pre-defined type contract. New helpers: `lib/storage.ts publicStorageUrl(storagePath)` (hardcodes `site-images` since hero rows only live there), `lib/queries/hero.ts loadHeroCarouselData()` returning `{ backgrounds, tiles }`. Component is `components/home/HeroCarousel.tsx`, ~210 lines. All behavior items implemented: `setInterval` 7000ms backgrounds, 11000ms tiles, pause-on-hover via onMouseEnter/Leave, pause-on-tab-hidden via `visibilitychange` listener, `prefers-reduced-motion` live-tracked via `matchMedia.addEventListener('change')` (not just read at mount). First background gets `priority` on next/image. Single-item arrays skip rotation; zero-item arrays fall back per the empty-states table. Scrim renders only when BOTH arrays are non-empty (stricter than the spec's empty-state table, which mentioned "with the scrim" for `bg=0, tiles>0` — on solid navy the scrim adds nothing because white text is already legible).
  - **Latent next.config.ts bug surfaced + fixed in the same commit.** `next/image` 500'd on the homepage with `hostname not configured`. The site's previous `next/image` callers had only ever fed `hero_image_url` (always null in site_settings) so the gap was latent. Added `images.remotePatterns` for `*.supabase.co` under `/storage/v1/object/public/**`.
- `8b35446` — **Visual polish.** `object-cover object-top` on background `<Image>` so cropping happens at the bottom. Section height +10%: `min-h-[55vh] md:min-h-[77vh]` on both the outer `<section>` and the inner foreground flex container (so vertical centering tracks the new height).
- **HeroCarousel.tsx:35 lint exception.** `setReducedMotion(mql.matches)` is a synchronous setState inside an effect; `react-hooks/set-state-in-effect` flags it. Acceptable cascading-render cost (one extra render at mount when reduce-motion is on). Proper fix is `useSyncExternalStore` — captured in followups.md.

**Print View PDFs + Coach Wallin update** (`specs/commit_print_view_pdfs_spec.md`). Two commits in one session.

- `c919aa3` — **Migration 038 + frontend swap (Part 1).** Configured the existing `documents` Storage bucket (created in/before migration 009 with no constraints): 5 MB cap, `application/pdf` only — UPDATE not INSERT. Public read policy on `storage.objects` was already provisioned by migration 009 ("Anyone reads public buckets"); no new policy needed. Added `pdf_storage_path text` + `schedule_pdf_storage_path text` to `rosters` — both nullable, hung on `rosters` because that's the only existing table at the per-team-per-year cardinality the spec wants for Option B "per-team schedule PDFs from day one" (one row per `(year, team_level, team_designation)`). Seeded 2025-26 paths: 4 roster PDFs (varsity / jv / freshman-Green + Blue both → shared freshman PDF) and 4 schedule PDFs (all → same shared 2025-26 schedule PDF). New `components/shared/PrintViewLink.tsx` (server component, hides when storagePath is null/undefined, sr-only "(opens PDF in new tab)" hint). Updated 5 pages: roster varsity/jv + roster freshman/[designation] + schedule games varsity/jv + schedule games freshman/[designation] + practice/[level]. The two game-schedule pages now fetch the matching `rosters` row in parallel via `Promise.all` to resolve `schedule_pdf_storage_path`. Practice schedule pages: Print button removed with NO replacement (no PDF in this scope). Deleted `components/schedule/print-button.tsx` + `print-footer.tsx` entirely (zero remaining consumers; their two `react-hooks/set-state-in-effect` lint errors are gone with them). New helper `lib/storage.ts publicObjectUrl(absolutePath)` sibling to `publicStorageUrl` — handles bucket-PREFIXED paths like `documents/rosters/varsity-2025.pdf` that the new rosters columns store. `Roster` interface extended with the two new nullable fields. `lib/queries/rosters.ts` does `select('*')` so the new columns flow through automatically.
- `cd27abb` — **Migration 039 — Coach Wallin update (Part 2).** SELECT before UPDATE confirmed his row at `id = a4e36da9-6371-4400-a9c7-dbed6ddce0fa` with name `Coach Wallin`, role `Position Coach`, role_category `position_coach`. NOT in the head coach slot (`role_category` is not `head`), so no slot clearing needed. UPDATE flipped name → `Douglas Wallin` and role → `Defensive Line Coach`; `role_category` untouched. Spec used the word "position" but the actual column is `role`.
- **Jeremy uploaded the four PDFs** to Studio after Commit 1 pushed. Files uploaded at their original source filenames (`2025 McNeil Football Rosters - Varsity.pdf` etc.); Jeremy then renamed in Studio to match the DB-seeded paths. One off-by-one remained:
- `4705b8b` — **Migration 040_fix_freshmen_pdf_path.sql.** DB had `freshman-2025.pdf` (singular, matching the `team_level` enum value); Jeremy's preferred filename was `freshmen-2025.pdf` (plural collective noun). Flipped both freshman rows (Green + Blue) to point at the plural path. Verified via `curl -I` that all four URLs return 200 OK.

**UI Freshman → Freshmen rename** (`a27a08c`). Per Jeremy ("collective...of men"). Touched `components/layout/teamLinks.ts` (header + mobile dropdown labels), both `[designation]` pages' `teamLabel` computation, `app/schedule/practice/[level]/page.tsx` `LEVEL_TITLES.freshman` + "Freshman Green & Blue" combined label. **Deliberately NOT touched** to preserve the schema/URL/code seam: `team_level = 'freshman'` enum value, URL slugs `/roster/freshman/...`, variable names `freshman_has_blue` / `freshmanHasBlue`, internal default-export function names (`FreshmanRosterPage`, `FreshmanGameSchedulePage`). The schema/URL/code identifiers remain singular; only user-visible strings flipped to plural.

**Other notes.**
- **apply_all.sql regen pattern** now skips `*_rollback.sql` (commit `6944994` updated `docs/CLAUDE.md`).
- `next.config.ts` `images.remotePatterns` now whitelists `*.supabase.co` under `/storage/v1/object/public/**`. Any future image bucket can render through `next/image` without further config.
- **`publicStorageUrl` and `publicObjectUrl` coexist** in `lib/storage.ts`. The former hardcodes `site-images` (hero callers); the latter handles full bucket-PREFIXED paths (PDF callers). Inline comments document the convention.
- `lib/hero.ts` is the StaticHero/site_settings hero loader; `lib/queries/hero.ts` is the HeroCarousel loader. **Distinct files, distinct concerns** — don't conflate.

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
10. **`specs/boosters_join_spec.md`** — Phase 1 pivot spec for `/boosters/join`. Google Form CTA tier ladder; supersedes the original Step 6 (Stripe Checkout). Turn 1 (migration 034) + Turn 2 (page + footer link) both shipped 2026-05-18. Future custom join flow is Phase 2+.

**Older docs (v1)** still useful as reference but no longer the source of truth:
- `specs/content_map.md` — booster-focused IA (pre-pivot)
- `specs/admin_scope.md` — original admin spec
- `specs/schema.md` — v1 schema (13 original tables; tables themselves unchanged, just extended in v2)
- `specs/build_plan.md` — original 20-step plan
- `spec_review.md` — resolution log; still useful for "why is X the way it is?"

**Project meta-docs (outside the repo, at the `MavericksWebsite/` parent directory):** `../../dns_audit.md`, `../../credentials.md`, `../../next_steps.md`, `../../sportsengine_capture.md`, `../../dns_raw/`. Kept outside git because `credentials.md` is sensitive and the rest are local-only reference data.

## Stack

- **Frontend**: Next.js **16.2.6** (App Router) + TypeScript (strict + `noUncheckedIndexedAccess`) + Tailwind v4 + shadcn/ui (`base-nova` style on `@base-ui/react`)
- **Type**: Lato (Google Fonts, weights 400/700/900) via `next/font/google` in `app/layout.tsx`. Replaces Geist as `--font-sans` site-wide as of `2ac698c`.
- **Hosting**: Vercel (auto-deploy from `main`)
- **Backend**: Supabase (Postgres + Auth + Storage + RLS)
- **Payments**: Stripe Checkout (guest checkout — no public user accounts)
- **Email**: Cloudflare Email Routing for role aliases (pending); Resend for contact-form delivery (wired in Step 4)
- **Repo**: GitHub org `github.com/McNeil-Mavs-Football-Boosters/mavericks-website` (public)

**Brand tokens** (defined in `app/globals.css` `@theme inline`):
- `--mavs-navy: #011858` — primary
- `--mavs-green: #1E541E` — secondary (semantic only — W result marker)
- `--mavs-brown: #7C5838` — tertiary (defined, unused)
- shadcn `--primary` aliased to `var(--mavs-navy)` so primitives adopt navy automatically

**Components installed in `mavericks-website/`:**
- shadcn primitives: `button`, `input`, `label`, `textarea`
- React deps: `react-hook-form`, `@hookform/resolvers`, `zod`, `resend`, `@next/mdx`, `@mdx-js/loader`, `@mdx-js/react`, `lucide-react`, `react-markdown` + `remark-gfm`
- **Lucide v1.x dropped brand glyphs** (trademark reasons). Inline SVGs in `components/layout/Footer.tsx` provide Facebook/Instagram/Youtube icons. If we add X/Twitter (anticipated in schema v2), keep inlining or add a brand-icon dep.

## What's live as of brand pass (`2ac698c`)

Most recent inventory. Supersedes the older "as of Deliverable E" and "as of Step 4b" sections below for the routes it covers; those sections remain as historical reference for everything that hasn't changed.

**Roster (`/roster/*`):**
- `/roster` → 308 redirect to `/roster/varsity`.
- `/roster/varsity` — "2025-26 Varsity Roster" header + 27-player table (migration 029, from the MaxPreps 2025-26 snapshot).
- `/roster/jv` — "2025-26 JV Roster" + 65-player table (migration 031, from `docs/2025 McNeil Football Rosters - JV.pdf`).
- `/roster/freshman/green` — "2025-26 Freshman Green Roster" (with "Green" in copy because `freshman_has_blue=true`) + 22-player table.
- `/roster/freshman/blue` — "2025-26 Freshman Blue Roster" + 27-player table.
- `/roster/freshman` → 404 (per spec — freshman URLs always carry designation).
- `/roster/varsity/anything`, `/roster/jv/anything`, `/roster/freshman/yellow` → 404.
- Per-row: jersey# (text, preserves "00"), Name (first + last), Position (verbatim from source — "WR/DB", "OL, DL", etc.), Grade ("Sr."/"Jr."/"So."/"Fr."), Height (verbatim — `5'11"`), Weight (`{n} lbs` or `—`). Sorted by sort_order ASC then numeric-aware jersey ASC. Mobile collapses to stacked cards (jersey + name, position · grade, height · weight).
- Print: PrintButton in page header + PrintFooter; reuses the same global `print:hidden` rules as schedule. Desktop table forces `print:block` so it renders on paper even from a mobile viewport.

**Coaches (`/coaches`):**
- `/coaches` — "Coaches & Trainers" h1, "2025-26" subhead. Sections render in fixed order: Head Coach → Coordinators → Position Coaches → Trainers → Staff. Empty sections are hidden EXCEPT Head Coach when empty, which shows the placeholder card with copy "Head Coach: position currently open. We'll update this page when the new coach is announced." Current data: Head Coach placeholder (no head row seeded), Coordinators = Michael Hale (Defensive Coordinator), Position Coaches = Coach Wallin, Trainers/Staff hidden.
- `/coaches/anything`, `/coaches/foo/bar` → 404.
- `export const dynamic = "force-dynamic"` (paramless DB-reading page).
- CoachCard: photo block (next/image with priority) OR default-avatar block (`bg-mavs-green`, white initials = first letter of first word + first letter of last word, decorative alt). h3 name, role, optional mailto/tel/markdown bio (each rendered only when non-null).
- No print support per spec.

**Year split state (DB):**
- `site_settings.current_year = '2025-26'` — governs football queries: rosters, players (via roster_id), practice_schedules, coaches, games. All flipped to 2025-26 by migration 030.
- `site_settings.current_board_year = '2026-27'` — governs `/boosters` board grid query. board_members untouched.
- `site_settings.freshman_has_blue = true` — Blue dropdown entry in header + `/roster/freshman/blue` + `/schedule/games/freshman/blue` all render. Migration 031 flipped the flag.

**Brand identity (live across every page):**
- **Primary: Navy `#011858`** — header logo wordmark, link hover, nav active, Game/Practice toggle active fill, Print button outline + text, MaxPreps "Live scores and stats →" CTA, hero CTA, Quick Links cards, dropdown chevrons, HOME badge + `bg-mavs-navy/5` row tint, footer link hover.
- **Secondary: Green `#1E541E`** — semantic only; W result marker (`text-mavs-green` in `result-cell.tsx`) and the default coach-card avatar block. (Note: existing Tailwind class `mavs-green` is now the darker brand shade, not the previous shade.)
- **Tertiary: Brown `#7C5838`** — `--mavs-brown` token defined but unused; available for future accents.
- **Type: Lato** (Google Fonts) via `next/font/google` in `app/layout.tsx`, weights 400/700/900. `--font-sans` points to Lato. h1 = `font-black uppercase tracking-tight`, h2 = `font-bold uppercase`, body = Lato 400 (Google Fonts doesn't publish Lato 500 / "Medium" — body uses 400). All h1 + h2 headings across every page were updated in the brand-pass commit.
- **Header logo**: `public/brand/mhs-logo.png` (sourced from `docs/MHS Logo.png` — the official primary lockup: horseshoe + horse + MHS Mavericks ribbon, full color). Rendered via `next/image` at 40×40 with `priority`. To its right: Lato Black uppercase navy wordmark "McNeil Mavericks Football" / "Mavs Football" on mobile.
- **Favicon**: `app/icon.png` (512×512) + `app/apple-icon.png` (180×180) — sourced from `docs/MHS Horseshoe Color.jpg` (clean horseshoe-only navy mark). Old `app/favicon.ico` deleted. Next.js App Router auto-picks these up.
- **Style guide PDF** + **11 logo source files** archived in `docs/` for future reference. The xlsx with student/guardian PII is gitignored (public repo).

## What's live as of Commit B Deliverable E (`32400b1`)

Adds to the Step 4b inventory below:

**Schedule (`/schedule/*`):**
- `/schedule` → 308 redirect to `/schedule/games/varsity`.
- `/schedule/games/varsity`, `/schedule/games/jv` — page header (title + "Live scores and stats →" MaxPreps subhead) + on-page Game/Practice toggle + **real games table** (seeded by migration 027, 5 varsity rows / 2 jv rows). Per-row: date "Fri, Sep 4", opponent (link to MaxPreps opens new tab when `opponent_url` set), location (link opens new tab when `location_url` set), HOME/AWAY/NEUTRAL badge, time "7:30pm" (America/Chicago), Result column (W/L/T for finals, em-dash for scheduled, Cancelled/Postponed pill, TBD), Watch icon when `watch_url` set, Homecoming-style notes as a small subtitle row spanning all columns. Subtle `bg-mavs-green/5` tint on home rows. Below 768px the table collapses to cards (same data, `block md:hidden` wrapper with `space-y-3`).
- `/schedule/games/freshman/green` — real games table for `team_designation='Green'` (2 seeded rows). Title and empty-state copy include "Green" only when `site_settings.freshman_has_blue = true`; plain "Freshman" otherwise.
- `/schedule/games/freshman/blue` — 200 (with a games-table render for `team_designation='Blue'`) only when `freshman_has_blue = true`, else 404. No blue rows seeded today; flag is `false`.
- `/schedule/games/varsity/*`, `/schedule/games/jv/*`, `/schedule/games/freshman/anything-else` — 404.
- `/schedule/practice/varsity`, `/schedule/practice/jv`, `/schedule/practice/freshman` — queries `practice_schedules` for current year + level + active. Renders markdown body when non-empty, `source_note` in empty-state card otherwise (current seed has empty body + `source_note='Awaiting practice schedule from coaching staff'`). Freshman practice title becomes "Freshman Green & Blue Practice Schedule" when `freshman_has_blue = true`; plain "Freshman" otherwise.
- `/schedule/practice/*/anything` — 404.
- **Print on every `/schedule/*` route.** Print button visible in the page header; Cmd-P or button click triggers `window.print()`. Header, footer, Game/Practice toggle, MaxPreps subhead, mobile cards, Watch icon all `print:hidden`. Table is `print:block` so the 7-column layout renders on paper regardless of viewport. Tints stripped, colored emphasis → `print:text-black`, badges become black-bordered. Print footer shows URL + formatted print date. Page margin `0.5in`. Empty-state copy stays on print so a no-data page isn't blank; only the MaxPreps action button inside the empty-state is hidden.

**Schedule layout** (`app/schedule/layout.tsx`) is a server component that primes `getSiteSettingsCore()` and renders the `<GamePracticeToggle>` above `{children}`. The toggle is a client component using `usePathname()`; on freshman game pages the Game button always links to `/schedule/games/freshman/green` (drops the designation per spec § 5 line 202 for the Practice link). The toggle wrapper has `print:hidden`. On `notFound()` inside `/schedule/*`, the schedule layout is unmounted and the root layout's `not-found.tsx` is rendered — header and footer still appear, but the toggle does not. Not a spec requirement to fix; revisit if it becomes a UX issue.

**Resources (`/resources`):**
- `/resources` — title "Forms & Links", subhead, 3 section headings rendered for the seeded data (Registration & Forms, Communications, Stadiums & Directions); empty sections (Resources, Other) render nothing. Each row: lucide icon (per `icon_hint`, defaults to ExternalLink), label as link (new tab + `rel="noopener noreferrer"` for non-`/` URLs), optional description below. SportsYou row uses the addendum-corrected `https://www.sportsyou.com/`. Empty-state card with `boosters@mcneilmavericks.org` copy renders if the entire table is ever empty.
- `/resources/*` — 404.
- `export const dynamic = "force-dynamic"` on the page so the build doesn't prerender it statically (Next 16 default-statics paramless pages with DB queries — spec § 9 requires per-request render).
- No print support (per spec § 9).

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
  `SUPABASE_DB_URL` is the Session pooler URI from Supabase Connect, with the password URL-encoded (`&` → `%26`, etc.). **Never echo `$SUPABASE_DB_URL`.** `db/apply_all.sql` remains as the concatenated bundle for one-paste via Supabase SQL Editor when psql is not handy; after any migration edit, regenerate via:
  ```
  for f in db/migrations/0*.sql; do
    case "$f" in *_rollback.sql) continue;; esac
    printf '\n-- ===\n-- %s\n-- ===\n\n' "$f"
    cat "$f"
  done > db/apply_all.sql
  ```
  The `*_rollback.sql` guard exists because rollbacks (e.g. `037_rollback.sql`) live alongside forward migrations in `db/migrations/` but must NOT be bundled into the forward-apply sequence — running them on a fresh DB would silently undo the seed.
- **Stripe should be created last** in the new-account chain so receipts come from a real `treasurer@mcneilmavericks.org` role address.
- **Migration of 35 existing Google Form signups**: 7 paid rows should go to `payments` with `method = 'other'`, NOT `'stripe'`. See schema.md migration plan and Step 12 of build_plan_v2.md.

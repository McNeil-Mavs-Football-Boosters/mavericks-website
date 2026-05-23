# Followups

Items surfaced during the Phase 1 build that aren't blocking the current step but need attention before launch or in early Phase 2. Append-only. Mark items done when resolved.

## Next pickup
- [x] ~~Remove the "Home" link from the desktop and mobile nav.~~ Done 2026-05-19, commit `afee45f`. Also removed from footer center-column `SITE_LINKS` for consistency ("no Home in any nav surface").
- [x] ~~Homepage Hero Carousel (3-turn rollout).~~ Done 2026-05-19 evening. Migrations 036 + 037, `components/home/HeroCarousel.tsx`, StaticHero moved to /boosters. Commits `279f47a` → `8b35446`.
- [x] ~~Print View PDFs replacing window.print() buttons; Coach Wallin → Douglas Wallin / Defensive Line Coach.~~ Done 2026-05-19 evening. Migrations 038 + 039 + 040 (freshmen plural fix). Commits `c919aa3` → `4705b8b`.
- [x] ~~UI rename Freshman → Freshmen on every user-visible label.~~ Done 2026-05-19, commit `a27a08c`. DB enum + URL slugs + code identifiers kept singular.

## Security
- [ ] Switch public read pages from `SUPABASE_SERVICE_ROLE_KEY` to the anon-key Supabase client so RLS is the actual gate. Affects: home + /about + /boosters + /boosters/join + /boosters/members + /contact + `/schedule/games/*` + `/schedule/practice/*` + `/roster/*` + `/coaches` + `/resources`. Anon RLS policies are in place (verified 2026-05-17 via `SET LOCAL ROLE anon` against `games`) — the fix is just wiring the right client. Defer until admin work begins or pick up as a small followup commit. Not blocking Commit B.
- [ ] Rotate Supabase anon key (exposed in chat 2026-05-16 during 4c setup). Studio → Settings → API → rotate, then update .env.local and Vercel env vars.
- [ ] Rotate Supabase service_role key (briefly in chat during original Steps 1-3 setup). Same process.
- [ ] Verify .env.local is gitignored and has never been committed (git log --all --full-history -- .env.local should return nothing).
- [ ] Investigate news-images Studio policy anomaly: Studio shows 4 policies on news-images while other migration-009 buckets show 0. May indicate Studio-side policies added outside of migrations. Run `SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND qual::text LIKE '%news-images%'` and reconcile against migration 009's policy array before launch.

## Brand assets
- [ ] **No white-on-transparent horseshoe variant** in the brand pack. `docs/W SHOE.png` is the white-horse-on-navy-horseshoe lockup (not pure white); `docs/MHS Text White Outline.png` is text-only. `/boosters/join` (slice 1 Turn 2, 2026-05-18) uses the existing full-color `public/brand/mhs-logo.png` on the green banner as a compromise — the white horse still pops on green but the green mane blends into the background. Ask the designer for a true white horseshoe (or white horseshoe + horse silhouette) on transparent PNG for use on dark / colored backgrounds; drop into `public/brand/mhs-horseshoe-white.png` and swap the import on the join banner.

## Routes still 404 (Step 5)
- [x] ~~Build `/sponsors` page.~~ Done 2026-05-22, commit `5ed2b4d` + sizing rewrite `f52b72e`. `app/sponsors/page.tsx` (server component, force-dynamic) + `app/sponsors/[catchall]/page.tsx` (notFound). Tier-grouped list, hide-if-empty per tier, MVP→Blue bounding boxes (`max-h-60 max-w-[440px]` → `max-h-24 max-w-[200px]`; rewrite from initial height-only to width-cap-aware after Sunflower's 384×42 aspect surfaced the horizontal-blowout risk), "Other Supporters" fallback for `tier_id IS NULL`, page-header + footer CTA both `<Link href="/boosters/sponsor">`. Footer CTA card uses `bg-mavs-green text-white` (not the spec's navy-on-green, which would fail WCAG AA). Spec: `specs/sponsors_page_spec.md`.
- [ ] **Build `/boosters/sponsor` page** — sales page for tier perks. The new "Become a Sponsor" `headline_cta` tile shipped 2026-05-22 targets this URL. Spec at `content_map_v2.md` `/boosters/sponsor` section. Tiers are in DB now (5 rows at year 2025-26 after migration 041's relabel).
- [ ] **Build `/boosters/donate` page** — existing carousel CTA already targets this. 404 today.
- [ ] **Build `/boosters/volunteer` page** — existing carousel CTA already targets this. 404 today.

## Pre-cutover content
- [ ] Replace 2025-26 review-period seed with real 2026-27 roster before public cutover. Includes: insert new rosters/practice_schedules/coaches rows at year='2026-27', migrate or insert new player rows, update site_settings.current_year='2026-27' in the same migration so headers and queries flip together. Current state: migrations 029/031/033 seeded V=27 + JV=65 + F-Green=22 + F-Blue=27 (= 141 players) under 2025-26 rosters; migration 032 seeded the real 2025 V/JV/F schedule (46 games, all `result_status='scheduled'`). Board stays at 2026-27 via site_settings.current_board_year.
- [ ] **2025 game results.** The 2025 season is over but the PDF in docs/ carries no scores. All 46 rows seeded by migration 032 use `result_status='scheduled'` so the Result column renders as em-dash. Backfill from MaxPreps once admin CRUD ships (or as a separate migration).
- [ ] **Opponent + location URLs missing.** Migration 032 seeded opponent_url and location_url as NULL on all 46 games. Populate from MaxPreps team pages once admin CRUD ships.
- [ ] 2025 varsity game results seeded for June 2 board demo. Add as a separate migration (018c or similar) after 025 lands, before the demo.
- [ ] Verify Kelly Reeves Athletic Complex address (10211 W Parmer Ln). Seeded value needs confirmation.
- [ ] SE Tier 1 capture: coach bios (non-Cruz), parent portal links, stadium info, SportsYou access code. Per site_pivot_addendum.md section 4. (Sponsor-logos line was here too — placeholder set in place 2026-05-22, see below.)
- [x] ~~SE Tier 1 capture: sponsor logos.~~ Placeholder set in place 2026-05-22, commit `732209c` / migration 041 — Rudy's (MVP) + 6 last-year Golds (AutoNation, Sunflower, LUV Braces, Dave's, TKO, Laurie Flood). Real 2026-27 sponsors swap in via admin (or a follow-up migration) once Kendra confirms at the June 2 board meeting.
- [ ] Confirm interim head coach contact at June 2 board meeting. That person owns football-side website content.
- [ ] Decide on additional coaches to seed beyond Wallin and Hale (Fanara, Hermes, Dubois pending verification).

## Visual checks pending (need browser, not CLI)
- [x] ~~**Sunflower Bank logo readability**~~ Confirmed fine 2026-05-23 by Jeremy on both homepage strip (~160×17.5) and /sponsors Gold tier (~280×30.6).
- [x] ~~**Lighthouse a11y ≥ 90** on `/`, `/sponsors`~~ Both scored 100/100 on 2026-05-23 (Jeremy ran Chrome DevTools → Lighthouse, Desktop, Accessibility only). Acceptance #9 cleared on both `sponsors_page_spec.md` and `homepage_sponsors_strip_restyle_spec.md`. The 10 "additional items to manually check" are Lighthouse's standard advisory list (keyboard focusability, tab order, etc. — things automated audits can't measure); spot-check pre-launch.
- [ ] **Lighthouse perf timeout on `/` staging.** When Jeremy ran a11y on the homepage 2026-05-23, Lighthouse flagged "the page loaded too slowly to finish within the time limit, results may be incomplete." The a11y audit completed (100/100) but the perf audit didn't. Likely Vercel preview/staging is slower than prod will be. Re-run perf-only on production after cutover; if the timeout repeats, investigate (image sizes, Supabase round-trips, hero carousel hydration).
- [ ] **Console-error sweep on `/` and `/sponsors`.** Triaged 2026-05-23: the only errors are 3 known-404 RSC prefetches that Next.js fires automatically when the homepage's `<Link>`s enter the viewport — `/boosters/donate`, `/boosters/volunteer`, `/boosters/sponsor`. All three routes are already on the "Routes still 404 (Step 5)" list above. Benign (the user-facing CTAs just navigate to the same 404 they always have), but Chrome surfaces every 404'd network call in the console. Two cleanup paths: (a) build the routes; (b) add `prefetch={false}` to the offending `<Link>`s as an interim. Jeremy 2026-05-23: do nothing yet — will clear naturally as the routes ship. Re-check console after each booster route lands; close this item when all 3 are built.

## Pre-cutover ops
- [ ] Second super_admin account for Carol with 2FA + recovery codes.
- [ ] Institutional super_admin accounts (president@, webmaster@) wired through Cloudflare Email Routing to personal inboxes.
- [ ] Mobile QA pass: open every public route on iPhone, fix anything broken. Step 14 territory.

## Spec drift to consolidate post-launch
- [ ] Collapse the v2 doc trail (site_pivot + addendum, schema_v2 + 3 addenda, content_map_v2 + 2 addenda, admin_scope_v2, build_plan_v2) into clean canonical docs. Per build_plan_v2 "Post-Step-20" section.
- [ ] Update CLAUDE.md to reflect Phase 1 completion state once cutover is done.

## Privacy / display preferences
- [ ] Anonymous donor option: donors must be able to choose "Anonymous" so their name does not appear on any public donor list/recognition. Needs flag on the donation record (and form UI) plus enforcement on whatever public surface renders donors.
- [ ] Member name-hide flag: members should be able to opt out of having their name displayed publicly. They are still a member of record, but no public surface (member lists, recognition, etc.) renders their identifying info. Needs flag on the member record (and signup/membership-edit UI) plus enforcement on every public query that touches members.

## "Visual polish (Phase 1.5)" section:

- ✅ Done (commit `2ac698c`, 2026-05-17). Brand pass — McNeil HS official style guide applied: navy (#011858) primary, green (#1E541E, recolored darker per guide) secondary, brown (#7C5838) tertiary token (defined, unused — kept for future accents), Lato (Google Fonts 400/700/900) replaces Geist site-wide, logo in header + horseshoe favicon, h1 Lato Black uppercase / h2 Lato Bold uppercase / body Lato regular. Style guide PDF + 11 logo originals live in `docs/`. Chosen assets copied to `public/brand/` and `app/icon.png` / `app/apple-icon.png`.
- Hero carousel on home page rotating background images every 6 seconds (stadium shots, game action photos). Gated on photo assets (Track A) + post-cutover.
- Real McNeil photography: players, stadium, sidelines, game action. Gated on Track A.
- Lato Medium (500) — the brand guide labels body weight as "Medium" but Google Fonts doesn't publish Lato 500; current build uses 400. If self-hosted Lato variable fonts ever land, revisit and switch body to true Medium.
- "Football Player & Guardian Name" xlsx is gitignored (PII; public repo). Currently sitting untracked in `docs/`. Move to `MavericksWebsite/private-data/` or another path outside the repo before cutover so it can't be `git add -f`'d by accident.

These are not blockers for Commit C or Phase 1 cutover. Capture so they don't get lost.

## Naming conventions (Phase 2+)
- **"Freshmen" is the user-facing collective noun** for the team. UI labels, page titles, and any new copy use "Freshmen" (plural). The DB enum value (`team_level = 'freshman'`), URL slugs (`/roster/freshman/...`), boolean flag (`site_settings.freshman_has_blue`), props (`freshmanHasBlue`), and default-export function names (`FreshmanRosterPage`, `FreshmanGameSchedulePage`) deliberately stay **singular** to preserve schema/URL/code stability. Source: 2026-05-19 evening, commit `a27a08c`. PDF filename in Storage is `freshmen-2025.pdf` (plural); migration 040 aligned the DB to match.

## Hero carousel — open items from spec (Phase 2+)
- **Admin UI for hero content.** `/admin/hero/backgrounds` (upload, reorder, enable/disable) and `/admin/hero/tiles` (CRUD for `headline_cta` + `sponsor_spotlight`). Phase 2. Admin write policies on `hero_background_images` + `hero_foreground_tiles` arrive with this work — the current RLS is read-only for anon + authenticated.
- ✅ Done 2026-05-22 (commit `732209c`, migration 041). **Sponsor spotlight tiles seed** — 3 featured sponsors (Rudy's, AutoNation, Sunflower) seeded with the updated payload shape `{ sponsor_name, logo_bucket, logo_storage_path, tagline?, website_url? }`. Logos live in `sponsor-logos/` (not `site-images/sponsors/` as originally planned). Shipped alongside the carousel two-pool rotation change and the homepage sponsors-strip restyle. See `specs/commit_sponsors_seed_and_carousel_spec_v2.md`.
- **Mobile photo variants.** If Lighthouse mobile flags hero images as too large, generate 768w variants of each photo and wire `next/image` `sizes` to use them on small viewports. Not blocking v1.
- **Featured-slide override.** Optional `hero_featured_override` row for championship-game-style coupled slides (photo + headline paired, both rotations suspended while active). Phase 2 or later.
- **`useSyncExternalStore` refactor for HeroCarousel reduced-motion.** `react-hooks/set-state-in-effect` flags `setReducedMotion(mql.matches)` inside the first useEffect. The proper React 18+ idiom for subscribing to a `matchMedia` (which is exactly what an "external store" is) is `useSyncExternalStore`. Acceptable as-is (one extra render at mount when reduce-motion is on), but worth a small cleanup pass. File: `components/home/HeroCarousel.tsx:32-43`.

## Print View PDFs — open items from spec (Phase 2+)
- **Admin UI for PDF uploads.** Right now Jeremy uploads via Studio and CC runs `UPDATE` statements. Phase 2: the roster edit form gets a "Replace PDF" button that uploads + updates the path in one action. Same for schedule. Same for any other PDF the site adds later.
- **Freshmen Green / Blue PDF split.** When coaches hand Jeremy team-specific freshmen PDFs, upload as `documents/rosters/freshmen-green-2026.pdf` and `documents/rosters/freshmen-blue-2026.pdf` and UPDATE only the Blue row (or both if Green diverges too).
- **PDF preview on the page itself.** Some district sites embed the PDF inline below the rendered roster instead of (or in addition to) linking it. Not in scope here; revisit if parents ask.
- **`publicStorageUrl` / `publicObjectUrl` reconciliation.** Two helpers now exist in `lib/storage.ts`: `publicStorageUrl(path, bucket='site-images')` (bucket-arg form, default `site-images`, used by HeroCarousel + homepage sponsors strip + sponsor_spotlight tiles after 2026-05-22) and `publicObjectUrl(absolutePath)` (handles bucket-PREFIXED paths, used by PrintViewLink). They serve different storage-path conventions. Long-term: pick one (probably collapse to the bucket-aware `publicStorageUrl`) and migrate callers. Not urgent.

## Lint baseline
- **`resource-item.tsx`** lines 43, 49: `react-hooks/static-components`. Pre-existing from Commit B Deliverable E. Component is being created during render via `iconForHint()`. Refactor to define the icon components at module scope and pick by hint.
- See HeroCarousel.tsx:35 item above for the third lint error.
- The `print-footer.tsx` lint errors (two `react-hooks/set-state-in-effect` on lines 10-13) **were resolved by deletion** in commit `c919aa3`.

## Phase 2 / deferred
- [ ] Bulk player import (paste mode primary, CSV upload optional). Spec'd in conversation 2026-05-16; folded into Step 7b admin rosters CRUD.
- [ ] Stats per player (Phase 2 pickup per addendum 2).
- [ ] Lake Travis "parking pass at tier" perk idea for membership ladder. Board input needed.
- [ ] Other Mavericks Sports outbound links on /resources page (after Jeremy has the URLs).

- Copy Roster function from previous season. I should be able to, as admin, go in and copy last year's JV team to Varsity, and freshman to JV. A couple of notes. Auto-drop seniors from varsity when doing the copy from JV, but don't drop anyone else. Make user do manual drops. When copying freshman to JV, copy both green and blue rosters. Drop any players that were Juniors because by rule they have to move up to varsity. BUT BIG warning to user. If you have not copied JV to Varsity, the JV roster is just going to get bigger and previous juniors will be dropped! Now the warning should ONLY happen if the roster is not empty. If it's empty we no the other roster was already moved for varsity. Write something better than that. Be sure we have functionality to move a single player between levels too. This is common and sometimes weekly. 

- wife wants roster and season images
- put bylaws document of booster club but only for board members. 


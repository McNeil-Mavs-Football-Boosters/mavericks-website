# Phase 1 Build Plan v2

Rewritten 2026-05-16 after the football pivot. **Supersedes the original `build_plan.md`** (which was structured around a booster-focused site).

Reads with `CLAUDE.md`, `spec_review.md`, `site_pivot.md` + `site_pivot_addendum.md`, `schema_v2.md` + addenda, `content_map_v2.md` + addenda, `admin_scope_v2.md`.

Two parallel tracks. Jeremy runs Track A (accounts, board, content gathering). CC runs Track B (code). Track B can start once Track A item J1 is done; the rest overlaps.

## Scope context

The original build plan called for a 1-2 weekend Phase 1. With the football pivot scope expansion (full schedule, roster, coaches, practice schedules, resource links, plus 19 admin CRUD pages instead of ~12), the realistic Phase 1 is **3-4 weekends plus a couple weeks of evenings.** Cutover target moves to **July 13-20 with a fallback to July 27** if Step 5 expansion runs long. SE lapses July 31, so July 29 remains the hard "must have shipped or cancel" date.

Jeremy confirmed: ship all of it, push cutover a week if needed. This plan reflects that.

## Hard dates

| Date | Event | What it gates |
|---|---|---|
| **Tue 2026-06-02** | Board meeting #1 (first Tuesday of June, per `booster_club_info.md` cadence) | Demo staging site, gather feedback. Soft gate. |
| **Tue 2026-07-07** | Board meeting #2 (first Tuesday of July) | Final board sign-off on cutover. Hard gate before DNS flip. |
| **Mon 2026-07-13** | Target cutover window opens | Earliest acceptable DNS flip. |
| **Mon 2026-07-20** | Target cutover window closes | Latest acceptable DNS flip for an unhurried cutover. |
| **Mon 2026-07-27** | Fallback cutover window | If Step 5 / 7b run long; eats into the SE renewal buffer. |
| **Wed 2026-07-29** | Last day to cancel SE for July 31 renewal | If we don't cancel here, SE bills another $1,385. |
| **Fri 2026-07-31** | SE subscription lapses | After this, SE rollback is gone. |

## Track A — Jeremy

Items J1-J3 done. Rest can happen in any order except as noted.

**J1. GitHub organization + empty repo.** ✅ Done — `github.com/McNeil-Mavs-Football-Boosters/mavericks-website` (public).

**J2. Vercel account + project.** ✅ Done — live staging at `mavericks-website-jeremy-vest-s-projects.vercel.app`.

**J3. Supabase project.** ✅ Done — project `rgdoolafpvhtsdpxbqvj`, 13 tables + auth.users provisioned per original Step 3.

**J4. 1Password Families shared vault.** Recommended, not blocking. Add Carol as second owner. Move credentials inventory items in as access lands. ~$60/yr split across officers.

**J5. Google Workspace for Nonprofits — DEFERRED** per credentials.md. Phase 1 uses Cloudflare Email Routing forwarders only.

**J6. Square account access (UPDATED 2026-05-26).** The booster club already has a Square account. Verify access has been transferred to the current board, recover credentials, and capture sandbox + production API keys + webhook signing secret. Replaces the original Stripe nonprofit-pricing application (Square was discovered 2026-05-26).

**J7. Booster bank account confirmation.** Talk to Chevon. Required for Square to actually deposit. Phase 1 can ship in Square sandbox mode and flip to live mode at the last minute (Step 15).

**J8. IRS determination letter + bylaws PDFs.** From Chevon. Two PDFs total. Needed for `/boosters/documents` content.

**J9. Cloudflare account.** Free tier. Add `mcneilmavericks.org` as a site. Configure DNS records mirroring SE today, except A/CNAME for apex and www point at Vercel. Do NOT change nameservers at Network Solutions yet.

**Set up Cloudflare Email Routing with these aliases forwarding to officers' personal addresses:**
- `boosters@` (general / info, route to multiple officers)
- `president@` → Carol's personal email
- `treasurer@` → Chevon's personal email
- `secretary@` → Jeremy's personal email
- `webmaster@` → Jeremy's personal email
- `sponsorship@` → Kendra's personal email

**`president@` and `webmaster@` are the institutional super_admin recovery accounts** per the admin scope. They forward to current officers personally, which means the institution survives officer turnover by just updating Cloudflare Email Routing — no Supabase Auth changes needed.

**J10. Content gathering at board meetings (June 2 + July 7).**
- Membership tier perks: board ratifies seed values
- Sponsorship tier perks: Kendra refines what McNeil can actually deliver
- "What dues fund" copy from Chevon
- Logo authorization status from Sylvia (school logos OK to use? if not, ship type-only)
- Confirm mailing address (#412, 6001 W Parmer Ln — already in existing site but verify)
- Confirm `/members` page heading wording: "thank you to our supporters" vs "dues-paid members"
- Get the new head coach's contact when one exists; that person owns football-side content

None of this blocks code. All ships as admin-editable content.

**J11 (NEW). SE Tier 1 capture pass.** Per `site_pivot_addendum.md` Section 4. Top priority:
- Sponsor logos from `/sponsors` (right-click save, drop in `legacy_capture/sponsor_logos/`)
- Individual coach bio pages (for Wallin, Fanara, trainers — anyone still on staff)
- Parent Portal sub-pages (HUDL, SportsYou access code, Fall Parent Meeting, Workouts)
- Stadiums page content
- Privacy policy PDF confirmation

Most time-sensitive item: sponsor logos. They go away when SE goes away. Do this in the next 1-2 weeks.

**J12 (NEW). Verify Kelly Reeves Athletic Complex address.** I seeded 10211 W Parmer Ln. Confirm before launch. Quick lookup or board confirmation.

**J13 (NEW). Confirm second super_admin (Carol).** Per admin scope, Carol gets a super_admin Supabase Auth account in addition to her personal one. Walk her through the recovery doc and 2FA setup before launch.

## Track B — CC

Steps 1-4 done. Step ordering for the rest:

---

### Step 4b (NEW). Nav + home reshape + /boosters landing

**Prereqs:** Step 4 shipped. Schema v2 not required yet.

**Why this step exists:** Step 4 shipped a booster-focused site. The football pivot reframes it. This is the smallest reshape that brings the existing Step 4 work in line with the new IA before Step 5 adds more pages.

**Deliverable:**

- **Header nav rewrite.** Replace current "Home / About / Contact" with the football-first nav per `content_map_v2.md`. Top-level items: Home, Schedule, Roster, Coaches & Trainers, News, Sponsors, Forms & Links, Boosters ▼, About. The Boosters dropdown lists 10 children (About, Join, Members, Sponsorship Opportunities, Volunteer, Committees, Board, Calendar/Events, Documents, Donate). Mobile drawer uses an accordion for Boosters.
- **Home page restructure.** Replace the current hero + about-the-club paragraph with the football homepage from `content_map_v2.md`: hero, Next Game card (with offseason fallback), Quick Links band (6 cards with lucide-react icons), Latest News section, Upcoming Events section, Sponsors strip, footer. Many sections will be empty pre-data and should hide gracefully.
- **New `/boosters` landing page.** Move the mission, "what dues fund" placeholder, board grid, and affiliations from the current `/about` to `/boosters`. The board grid query stays the same; just relocated.
- **Updated `/about` page.** Becomes meta-about-the-site (not the booster club). New shorter copy explaining what the site is and who runs it. Contact form stays here.
- **Footer additions.** Add social icon row with placeholder icons (lucide-react), each hiding when the corresponding URL field on site_settings is null. Address line in column 1 still pulls from `site_settings.mailing_address`.

**Acceptance:**
- All four routes from Step 4 still resolve. `/about` and `/boosters` both render with appropriate content.
- Header nav renders correctly on desktop and mobile. Boosters dropdown opens on hover (desktop) and tap (mobile accordion).
- Homepage shows hero + Quick Links band even with no game/news/event data (graceful empty states).
- Vercel preview deploy succeeds; no console errors.

**Rollback:** revert the commit. Step 4 work resumes serving.

**Estimate:** 1 evening to a half day.

---

### Step 4c (NEW). Apply schema v2 migrations

**Prereqs:** Step 4b shipped. Schema docs locked.

**Deliverable:** Apply the new migrations from schema_v2.md, schema_v2_addendum.md, schema_content_v2_addendum2.md, schema_content_v2_addendum3.md to the Supabase project. Migrations in order:

```
011_football_pivot_types.sql       (5 enums)
012_football_pivot_tables.sql      (games, rosters, coaches, resource_links)
013_players_table.sql              (players + index + trigger)
014_site_settings_additions.sql    (current_year, season fields, maxpreps URL)
015_football_pivot_triggers.sql    (touch_updated_at on new tables)
016_football_pivot_rls.sql         (RLS policies on games, rosters, coaches, resource_links)
017_players_rls.sql                (RLS on players)
018_football_pivot_seed.sql        (initial seed including Coach Wallin)
019_team_designation.sql           (ALTER games, rosters; rebuild unique index)
020_practice_schedules.sql         (table + index + trigger)
021_practice_schedules_rls.sql
022_sponsorship_inquiries.sql      (type + table + index + trigger + RLS)
023_site_settings_socials.sql      (ALTER site_settings, rename column)
023b_site_settings_freshman_blue.sql (ALTER site_settings ADD freshman_has_blue)
024_practice_schedules_seed.sql    (3 stubs)
```

Plus `coach-photos` Storage bucket via Supabase Studio (manual, document in README).

**Acceptance:** all 18 tables visible in Supabase Studio (13 original + 5 new). RLS enabled on every new table. Anon SELECT on `games` returns empty array (no rows yet, but works). Anon SELECT on `rosters` returns 3 seeded stubs.

**Rollback:** `DROP TABLE` the new tables in reverse order, or full schema reset (`DROP SCHEMA public CASCADE` + re-run all migrations 001-024). Free to do until production goes live.

**Estimate:** 1 evening.

---

### Step 5 (EXPANDED). Public collection routes

**Prereqs:** Steps 4b, 4c shipped.

**Deliverable:** every public route from the route map in `content_map_v2.md`. Read-only, RLS-public, with proper empty states. Roughly 16-18 routes depending on freshman subdivisions.

The full list:

**Schedule routes:**
- `/schedule` (301 redirect to `/schedule/games/varsity`)
- `/schedule/games/[level]` (varsity, jv)
- `/schedule/games/freshman/[designation]` (green, plus blue when flag is true)
- `/schedule/practice/[level]` (varsity, jv, freshman)

**Roster routes:**
- `/roster` (301 redirect to `/roster/varsity`)
- `/roster/[level]` (varsity, jv)
- `/roster/freshman/[designation]` (green, plus blue when flag is true)

**Other public routes:**
- `/coaches`
- `/news` (index with pagination)
- `/news/[slug]` (article detail)
- `/sponsors`
- `/resources`

**Boosters section:**
- `/boosters` (already done in 4b)
- `/boosters/members`
- `/boosters/sponsor` (sales page, form posts to Step 11)
- `/boosters/volunteer`
- `/boosters/committees`
- `/boosters/board`
- `/boosters/events` (index)
- `/boosters/events/[slug]` (detail)
- `/boosters/documents`

`/boosters/join` and `/boosters/donate` deferred to Step 9 (they need Square wired up).

**Implementation patterns:**
- All server components, pulling from Supabase via `lib/supabase/server.ts`
- `export const revalidate = 60` on each route — admin edits show up within a minute
- Empty states hide sections rather than show "No items found" boxes (per `content_map.md` from original spec)
- Mobile-responsive (tables collapse to cards at <768px)
- Print stylesheet for schedule and roster pages

**Acceptance:**
- Every route renders with seed data or graceful empty state
- Anchor jumps work on tabbed pages (`/schedule/games/varsity` etc.)
- Console-clean in incognito mode (proves anon RLS works)
- Lighthouse a11y ≥ 80 (final hardening is Step 14, just don't ship broken a11y now)

**Rollback:** revert per route if any one is half-baked. Routes are isolated.

**Estimate:** 3-5 evenings, or a long weekend. The cookie-cutter pattern means later routes get faster.

---

### Step 6 (UPDATED). Admin auth

**Prereqs:** Step 5.

**Deliverable:** unchanged from original Step 6, plus:

- Two super_admin Supabase Auth accounts created during this step (not just Jeremy's):
  1. Jeremy's personal email
  2. Carol's personal email (Carol = second active super_admin per admin_scope_v2)
- Plus two institutional Auth accounts as recovery paths:
  3. `president@mcneilmavericks.org` (super_admin role)
  4. `webmaster@mcneilmavericks.org` (super_admin role)
- All passwords stored in 1Password Families vault
- Recovery codes generated for each, also stored in vault

**Document** the recovery flow in the project README:
1. New officer can't log in
2. Goes to `/admin/login` → "Forgot password"
3. Enters `president@mcneilmavericks.org`
4. Supabase emails reset link → Cloudflare routes to current president's personal inbox
5. They set new password, they're in

**Acceptance:** existing acceptance + Jeremy can log in as Jeremy, Carol can log in as Carol, both have super_admin role, both can invite a test third admin. Password reset for `president@mcneilmavericks.org` arrives at the configured forwarding address.

**Rollback:** revert middleware/UI changes. Auth rows can stay.

**Estimate:** 1-2 evenings.

---

### Step 7 (UPDATED). Admin CRUD — Tier A1 (news, events, settings)

**Prereqs:** Step 6.

**Deliverable:** unchanged from original. The three admin pages are now part of a larger set, but this step still ships first as it's the simplest pattern.

- `/admin/news` (CRUD + draft/publish + TipTap)
- `/admin/events` (CRUD + status toggle)
- `/admin/settings` (singleton form, includes `current_year` and `freshman_has_blue` toggles per admin_scope_v2)

Settings page additions vs original:
- `current_year` field with prominent label
- `freshman_has_blue` toggle with warning copy
- Social URL fields (Facebook football, Facebook boosters, X football, X boosters, Instagram, YouTube — all optional)
- `season_label`, `season_opener_date`, `next_game_override`, `maxpreps_team_url`

**Acceptance:** unchanged from original Step 7.

**Estimate:** 2 evenings.

---

### Step 7b (NEW). Admin CRUD — football content

**Prereqs:** Step 7.

**Deliverable:** five admin pages for the football content types. Per `admin_scope_v2.md` per-page detail:

- `/admin/games` — schedule CRUD with score entry, status auto-flip, designation picker
- `/admin/rosters` (list of three rows per year) + `/admin/rosters/[id]` (detail with nested players CRUD, bulk-add, drag-reorder)
- `/admin/coaches` — CRUD with role_category dropdown, photo upload to `coach-photos`, head coach warning logic
- `/admin/practice-schedules` — three editable rows per year, markdown body
- `/admin/resource-links` — CRUD grouped by section, drag-reorder within section

All follow the same patterns from Step 7 (TipTap for markdown bodies, image uploads where applicable, save state visible, soft-archive over hard delete).

**Acceptance:**
- Jeremy creates a game in admin → shows on `/schedule/games/varsity` within 60s
- Jeremy creates 5 players on the Varsity roster (mix of bulk-add and inline-add), sees them on `/roster/varsity`
- Jeremy enters Wallin as a Position Coach, sees him on `/coaches`
- Jeremy edits the Varsity practice schedule body, sees it on `/schedule/practice/varsity`
- Jeremy adds an Aktivate link to resource_links, sees it on `/resources`

**Rollback:** per-page revert. Content stays in DB.

**Estimate:** 3-4 evenings. Rosters page is the most complex; everything else is the standard pattern.

---

### Step 8 (UPDATED). Admin CRUD — Tier A2 (tier configs)

**Prereqs:** Step 7b.

**Deliverable:** unchanged from original.

- `/admin/membership-tiers` (CRUD + perks array editor + drag-reorder + badge_label)
- `/admin/sponsorship-tiers` (same pattern)

**Acceptance:** unchanged.

**Estimate:** 1-2 evenings.

---

### Step 9 (UPDATED 2026-05-26). Square — membership flow (sandbox mode)

**Prereqs:** Step 8, J6 (Square sandbox credentials).

Provider swapped from Stripe to Square 2026-05-26. Builds `/boosters/join` (the form deferred from Step 5), `/api/memberships/create`, `/api/square/webhook`. Handles Free Fan Base $0 bypass, idempotent webhook, success/cancel pages. Likely uses Square Checkout (hosted) for the same UX shape Stripe Checkout would have provided; confirm at implementation time once Square API access is in hand.

**Estimate:** 2-3 evenings.

---

### Step 10 (UPDATED 2026-05-26). Square — donation flow (sandbox mode)

**Prereqs:** Step 9.

Builds `/boosters/donate` (deferred from Step 5). Reuses Square webhook handler with `purpose='donation'`. Standalone from membership per `content_map_v2.md`.

**Estimate:** 1 evening.

---

### Step 11 (UPDATED). Admin — memberships and sponsorship inquiries

**Prereqs:** Step 9.

**Deliverable:** original Step 11 (memberships admin) plus the new sponsorship_inquiries pages.

- `/admin/memberships` — list, filter, edit, manual-mark-paid, soft-delete, CSV export
- `/admin/sponsorship-inquiries` — list, filter by status, detail page with status workflow, "convert to sponsor" action

Plus the `/boosters/sponsor` form submission flow: server-side endpoint `/api/sponsorship/create`, Resend email to Kendra on new inquiry.

**Acceptance:** Jeremy submits a test sponsorship inquiry from `/boosters/sponsor`, sees it in `/admin/sponsorship-inquiries` with status='new'. Kendra (test account with content_admin) receives email notification.

**Estimate:** 2 evenings.

---

### Step 12 (UNCHANGED). Migrate 35 existing signups

**Prereqs:** Step 11, Jeremy exports the 2026-27 Google Form to CSV.

Unchanged from original. One-time script at `scripts/migrate_2026_27.ts`.

**Estimate:** 1 evening + Jeremy's CSV export.

---

### Step 13 (UPDATED). Admin CRUD — Tier B

**Prereqs:** Step 11.

**Deliverable:** original Step 13 set (sponsors, board, documents, volunteer, committees) plus the year-context surfacing requested by admin_scope_v2.

- `/admin/sponsors` (CRUD + logo upload to `sponsor-logos`)
- `/admin/board` (CRUD + photo upload to `board-photos`, year filter)
- `/admin/documents` (CRUD + PDF upload to `documents` bucket, type tagging)
- `/admin/volunteer-opportunities` (CRUD)
- `/admin/committees` (CRUD)

All reuse patterns from earlier steps.

**Estimate:** 2 evenings.

---

### Step 14 (UPDATED). Hardening

**Prereqs:** Step 13.

**Deliverable:** unchanged from original plus:

- Verify password reset flow works for `president@mcneilmavericks.org` end-to-end (real Cloudflare Email Routing path, not local mock)
- Confirm `freshman_has_blue` toggle flows: false → true creates Blue tab in nav within 60s; true → false hides it within 60s
- A11y ≥ 90 on the new public routes too (`/schedule/games/varsity`, `/roster/varsity`, `/coaches`, `/resources`)

**Estimate:** 1-2 evenings.

---

### Step 15 (UPDATED 2026-05-26). Square live mode

**Prereqs:** Step 14, J6 + J7 done.

Provider-swapped (Stripe → Square) but otherwise unchanged from original plan. Real $1 charge test, Treasurer (Chevon) granted readonly_admin access to verify she can see the payment.

**Estimate:** 1 evening.

---

### Step 16 (UNCHANGED). Board walkthrough

**Prereqs:** Step 15. Date: **July 7 board meeting**.

Demo on staging URL (vercel.app or `mcneilmavericks.com` if you choose to use the existing WebForwarder for staging). Walk officers through making a news post, editing tier prices, viewing payments dashboard. Each officer logs in once during the meeting.

**Acceptance:** board votes to proceed with cutover.

**Rollback:** defer cutover one cycle; SE keeps running.

---

### Step 17 (UPDATED). Pre-cutover prep

**Prereqs:** Step 16. Do this 48-72 hours before chosen cutover day.

Unchanged from original plus:

- **Verify recovery flow:** Jeremy does a real password reset from `president@mcneilmavericks.org` to prove the Cloudflare Email Routing → personal inbox path works for the institutional super_admin
- **Verify Carol can log in** as super_admin from her own credentials
- **Confirm 2FA enrollment** for Jeremy and Carol (TOTP + downloaded recovery codes stored in 1Password)
- **Final SE capture sanity check:** sponsor logos saved locally, no critical content lost

**Acceptance:** all the above completed, plus the original Step 17 prep (Vercel domain added, Cloudflare zone verified, TTL lowered).

**Estimate:** 2-3 hours.

---

### Step 18 (UNCHANGED). Cutover

**Prereqs:** Step 17. Target: **Monday July 13 - Monday July 20** (fallback July 27).

Network Solutions nameserver change to Cloudflare. Vercel issues SSL. Square webhook URL updated to production. Verification checklist runs.

**Rollback:** Network Solutions nameservers back to `ns1-5.sportnginserver.com`. SE site resumes. Under 30 minutes plus DNS TTL.

---

### Step 19 (UNCHANGED). Post-cutover monitoring

7 days. Daily checks on Vercel logs, Supabase logs, Square dashboard. Manual outreach to first 3-5 real signups.

---

### Step 20 (UNCHANGED). SE termination

By **2026-07-29.** Cancel SE subscription, screenshot confirmation, update credentials.md.

---

### Post-Step-20 (NEW). Documentation cleanup

Not a numbered build step. After the dust settles on launch (~Aug 1):

- Consolidate the addendum trail (`site_pivot.md` + addendum, `schema_v2.md` + 3 addenda, `content_map_v2.md` + 2 addenda, `admin_scope_v2.md`, this `build_plan_v2.md`) into clean canonical docs that replace the trail. The addenda stay as a decision log; the canonical docs become the future implementation reference.
- Update CLAUDE.md to reflect Phase 1 completion and the actual state of Phase 2 / Phase 3.
- Archive obsolete bits of `next_steps.md` (the credential outreach items, since they'll be resolved).

**Estimate:** half a weekend.

---

## Time budget summary

| Phase | Estimate | Weeks |
|---|---|---|
| Step 4b + 4c | 1-2 evenings | Week of May 19 |
| Step 5 | 3-5 evenings | Weeks of May 19-26 |
| Step 6 | 1-2 evenings | Week of May 26 |
| Step 7 + 7b + 8 | 6-8 evenings | Weeks of May 26 - June 9 |
| Step 9 + 10 | 3-4 evenings | Week of June 9-16 |
| **Demo at June 2 board meeting** (intermediate) | — | Tue June 2 |
| Step 11 + 12 + 13 | 5 evenings | Weeks of June 16-30 |
| Step 14 (hardening) | 1-2 evenings | Week of June 30 |
| Step 15 (Square live) | 1 evening | Week of July 7 (after board sign-off) |
| **Step 16 — board sign-off** | — | Tue July 7 |
| Step 17 (pre-cutover) | 2-3 hours | Days before cutover |
| Step 18 (cutover) | 1 evening | Window July 13-20 |
| Step 19 (monitoring) | 7 days, light | July 13-27 |
| Step 20 (SE cancel) | 30 min | By July 29 |

Total CC evening time: roughly **20-30 evenings over 10 weeks** including buffer. Cleanly fits "side project, evenings and weekends" if you're consistent. Realistic risk: Step 5 expansion or Step 7b rosters complexity eating an extra weekend. Build the buffer; use it if needed.

## Demo to the June 2 board meeting

The first board meeting falls in the middle of this build, before admin CRUD is fully done. What to show:

- The public side at staging URL: home, schedule (empty but with structure visible), roster, coaches (with Wallin), `/boosters` landing, sponsors page
- The visual reframe: "this is now a football website, not a brochure"
- The Quick Links band on home and what each button will do
- Mobile responsiveness (open it on a phone for the meeting)
- **Ask**: confirmation on sponsorship tier perks (Kendra), mission-statement-area copy (Carol), volunteer opportunities text (Kendra)

Don't show admin yet. Don't demo the join flow yet (it won't exist until Step 9).

## Open decisions before CC starts Step 4b

These are smaller than the open decisions before the original Step 1. None block, but answer them when convenient:

1. **Rich text editor finalization.** TipTap was my recommendation in original build_plan; still my pick. Lexical is more powerful but heavier. Confirm or override.
2. **Staging URL strategy.** Vercel-generated `mavericks-website.vercel.app` vs. pointing the unused `mcneilmavericks.com` (Network Solutions WebForwarder, currently → `.org`) at Vercel during build. Option 2 makes a friendlier URL for board demos. My pick: option 2.
3. **When to invite Carol / Ashley / Chevon to admin.** July 7 meeting (one-time ceremony) or earlier as each is available. My pick: earlier, spreads the "wait, I can't log in" debugging.

DNS provider (Cloudflare) and email strategy (forwarders-only) settled.

## First instruction for CC

When Jeremy says go:

> Implement Step 4b of build_plan_v2.md. Rewrite the header nav to the football-first 9-item structure with Boosters dropdown. Restructure the home page with hero + Next Game (graceful empty state) + Quick Links band (6 cards with lucide-react icons) + Latest News section + Upcoming Events section + Sponsors strip. Create a new `/boosters` page that takes the mission + board content currently on `/about`. Update `/about` to be a shorter "about the site" page that still includes the contact form. Add footer social icon placeholders that hide when site_settings social fields are null. Push to main, confirm Vercel preview, report the staging URL.

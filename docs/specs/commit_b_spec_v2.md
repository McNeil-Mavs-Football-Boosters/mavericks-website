# Commit B Spec: current_year swap + public read-only routes

Written 2026-05-16. Sits under `build_plan_v2.md` Step 5; concretely it is the first slice of Step 5. Splits Step 4c into:

- **Commit A (shipped 2026-05-16):** migrations 011 through 026, RLS, `coach-photos` bucket, repo + Supabase wiring.
- **Commit B (this doc):** code swap of hardcoded `'2026-27'` to a runtime read from `site_settings.current_year`; public read-only rendering of `/schedule`, `/roster`, `/coaches`, `/resources`. No admin CRUD.

Reads with: `schema_v2.md`, `schema_v2_addendum.md`, `schema_content_v2_addendum2.md`, `schema_content_v2_addendum3.md`, `content_map_v2.md`, `admin_scope_v2.md`, `build_plan_v2.md`.

Estimate from CLAUDE.md: **2-3 evenings.** Spec confirms that estimate assuming no scope creep.

---

## 1. What is in scope

| Area | Deliverable |
|---|---|
| Shared | `getCurrentYear()` helper reading `site_settings.current_year`; every existing `'2026-27'` literal in code swapped to use it |
| Schedule | Routes for `/schedule`, `/schedule/games/[level]`, `/schedule/games/freshman/[designation]`, `/schedule/practice/[level]`; header dropdown nav; on-page Game/Practice toggle |
| Roster | Routes for `/roster`, `/roster/[level]`, `/roster/freshman/[designation]`; header dropdown nav; player table render |
| Coaches | `/coaches` with section-per-`role_category` |
| Resources | `/resources` with section-per-`resource_section` |
| Validation | 404 handling for invalid level/designation combinations |
| Empty states | Per-page empty copy as specified in content map |
| Print | Print button + print stylesheet on schedule (games + practice) and roster pages |

## 2. What is explicitly out of scope

All of these are later commits or later phases. Do not implement in Commit B even if the path crosses your mind while building.

- Admin CRUD for any of these content types (`/admin/games`, `/admin/rosters`, etc. land in Step 7b/13)
- `/news` and `/news/[slug]`
- `/sponsors`
- `/boosters` and any subpages beyond what Step 4b already shipped
- `/about` updates (already done in Step 4b)
- `/privacy` MDX
- Stripe, payment forms, donation form
- File uploads (no photo uploads to `coach-photos` yet)
- Auth (`/admin` redirects to coming-soon page or 404; out of Commit B)
- Player photos (decided: not Phase 1; schema accommodates later)
- Search
- ICS export from schedule
- Social share buttons
- Pagination on any list (none of the Commit B pages exceed a single page worth of rows)
- Sponsor logos / news article carousel on home (those live on home page, which is Step 4b; revisit only if home references broken)

## 3. Prerequisites

These must all be true before starting:

- Step 4 and Step 4b shipped to staging (header nav, footer, home shell already rendering)
- Commit A complete: migrations 011-026 applied, all 20 tables visible, RLS passing
- Three seed rows in `rosters` for `2026-27` (varsity, jv, freshman green)
- Three seed rows in `practice_schedules` for `2026-27` (varsity, jv, freshman)
- Coach Wallin seed row exists in `coaches`
- `resource_links` seed rows present (verify against schema_v2 seed and the SportsYou correction in addendum)
- `site_settings.current_year` exists and equals `'2026-27'`
- `site_settings.freshman_has_blue` exists and equals `false`
- `site_settings.maxpreps_team_url` exists and equals the McNeil MaxPreps URL

If any of these is missing, fix first via a small follow-up migration. Do not paper over in code.

---

## 4. Deliverable A: current_year swap

### Problem

Existing Step 4b code has `'2026-27'` literals in places that should be reading from `site_settings.current_year`. Hardcoding works for staging but breaks every July when the school year rolls.

### Spec

1. **Add a helper.** Server-side function (in `lib/site-settings.ts` or similar; placement is the builder's call) that:
   - Reads the singleton `site_settings` row
   - Returns at minimum `current_year`, `maxpreps_team_url`, `freshman_has_blue`
   - Caches per-request (React `cache()` or equivalent) so a single render does not hit Postgres N times

2. **Find every `'2026-27'` in code.** Replace with the helper. Known sites from prior specs:
   - Home page "Quick Links" cards labeled `2026-27 Schedule` and `2026-27 Roster`
   - Any board grid query in `/boosters` or `/about` that filters `board_members.year = '2026-27'`
   - Any sponsor strip on home that filters `sponsors.year = '2026-27'`
   - Anything else `grep` turns up

3. **Acceptance:** `grep -r "2026-27" app/ components/ lib/` returns no results in TS/TSX files. Search results in migrations and seed SQL are fine and expected; only code is scrubbed.

4. **Sanity test:** in Supabase Studio, change `site_settings.current_year` to `'2027-28'`, redeploy or revalidate, confirm every page that previously said "2026-27" now says "2027-28." Revert.

### Notes

- The `current_year` value is intentionally a text year-pair string (e.g., `'2026-27'`), not a date or integer. Display verbatim.
- `freshman_has_blue` is read in routes that conditionally render Blue dropdown items and Blue pages. See Section 5.

---

## 4.5. Deliverable A.5: Header dropdowns + footer rework

**Locked 2026-05-17.** Inserted between Deliverable A (current_year swap) and Deliverable B (Schedule routes) because Schedule and Roster both depend on the new dropdowns being in the main header.

### Header changes

Step 4b shipped a header with plain links for Schedule, Roster, Coaches & Trainers, News, Sponsors, Forms & Links, plus a Boosters dropdown. This deliverable converts Schedule and Roster from plain links to dropdowns matching the Boosters pattern.

**Schedule dropdown contents** (read `freshman_has_blue` from `getSiteSettingsCore`):

| When | Items |
|---|---|
| `freshman_has_blue = false` | Varsity → `/schedule/games/varsity`<br>JV → `/schedule/games/jv`<br>Freshman → `/schedule/games/freshman/green` |
| `freshman_has_blue = true` | Varsity → `/schedule/games/varsity`<br>JV → `/schedule/games/jv`<br>Freshman Green → `/schedule/games/freshman/green`<br>Freshman Blue → `/schedule/games/freshman/blue` |

**Roster dropdown contents** (same team list, different base paths):

| When | Items |
|---|---|
| `freshman_has_blue = false` | Varsity → `/roster/varsity`<br>JV → `/roster/jv`<br>Freshman → `/roster/freshman/green` |
| `freshman_has_blue = true` | Varsity → `/roster/varsity`<br>JV → `/roster/jv`<br>Freshman Green → `/roster/freshman/green`<br>Freshman Blue → `/roster/freshman/blue` |

**Behavior:** click to open (same as Boosters dropdown). Each menu item is a direct navigation. No hover-open. No nested submenus. Mobile drawer renders dropdowns as accordions, matching the existing Boosters mobile pattern.

**Top-level link text** in the header is still "Schedule" and "Roster" (unchanged); only the click behavior changes (from direct navigation to opening a dropdown).

### Footer rework

Step 4b shipped a footer that takes up roughly half a screen of vertical space. Slim it down:

1. **Site links horizontal.** The "Site" column currently stacks `Home / Schedule / Boosters / Sponsors / Donate / About / Privacy` vertically. Convert to a single horizontal row separated by middle dots or pipes: `Home · Schedule · Boosters · Sponsors · Donate · About · Privacy`.

2. **Three-column layout tightened.** Address column (left), site links row (now horizontal, center), connect column (right) all on one row at desktop widths. Mobile stacks them but with tighter spacing than current.

3. **Combine disclaimer and copyright into a single paragraph.** Currently the disclaimer ("This website is maintained by...") is one block and the copyright line is below it. Combine into one paragraph at the bottom. Example: "This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website. © 2026 McNeil Maverick Football Booster Club · 501(c)(3) · EIN 26-4231242."

4. **Tighten vertical rhythm everywhere.** Reduce line-height and font-size on the link list and address; reduce padding above and below the footer.

**Target:** footer vertical height roughly halved compared to Step 4b.

### Scope note

These changes are not Schedule-specific. They affect every page that uses the global layout (home, /about, /boosters, etc.). That's fine; this is a global header/footer pass, not a Schedule pass. Vercel preview should reflect the changes on every existing page.

### Cleanup from Pass 2 step 1

The schedule layout shipped in commit `2736001` contains the now-obsolete three-row sticky nav (Type / Level / Designation). Remove it as part of this deliverable. The new schedule layout will be much smaller: page header (handled by individual pages), Game/Practice toggle (single segmented control), and `{children}`. No team-level nav inside the page.

---

## 5. Deliverable B: Schedule routes

### Route map (Commit B scope)

| Path | Behavior |
|---|---|
| `/schedule` | 301 redirect to `/schedule/games/varsity` |
| `/schedule/games/varsity` | Renders varsity games |
| `/schedule/games/jv` | Renders JV games |
| `/schedule/games/freshman` | 404 (no canonical URL for freshman without designation) |
| `/schedule/games/freshman/green` | Renders freshman green games (always present) |
| `/schedule/games/freshman/blue` | If `freshman_has_blue = true`, renders blue games; else 404 |
| `/schedule/games/varsity/[anything]` | 404 (varsity has no designation) |
| `/schedule/games/jv/[anything]` | 404 (JV has no designation) |
| `/schedule/practice/varsity` | Renders varsity practice |
| `/schedule/practice/jv` | Renders JV practice |
| `/schedule/practice/freshman` | Renders freshman practice (shared, no designation in URL) |
| `/schedule/practice/freshman/[anything]` | 404 (practice never has designation in URL) |
| `/schedule/practice/varsity/[anything]` | 404 |
| `/schedule/practice/jv/[anything]` | 404 |
| Any other `/schedule/*` | 404 |

### Header navigation (replaces in-page tab nav)

**Decision locked 2026-05-17:** Schedule navigation lives in the main site header as a dropdown menu, modeled after the existing Boosters dropdown. There is no in-page sticky tab nav for team level selection.

**Main header Schedule dropdown** opens to a flat list of teams:

When `freshman_has_blue = false`:
- Varsity → `/schedule/games/varsity`
- JV → `/schedule/games/jv`
- Freshman → `/schedule/games/freshman/green` (the Green substructure is invisible to users when there is no Blue)

When `freshman_has_blue = true`:
- Varsity → `/schedule/games/varsity`
- JV → `/schedule/games/jv`
- Freshman Green → `/schedule/games/freshman/green`
- Freshman Blue → `/schedule/games/freshman/blue`

The dropdown opens on click (matching the existing Boosters dropdown behavior). Each item lands directly on that team's **Game** page.

Roster gets the same dropdown pattern with the same team list, each item landing on `/roster/[level]` or `/roster/freshman/[designation]`. See Section 6.

### Shared layout

`app/schedule/layout.tsx` (or equivalent). Renders for every `/schedule/*` route:

1. **Page header**
   - Title: `[current_year] [Level] [Game|Practice]` (e.g., "2026-27 Varsity Game Schedule", "2026-27 Freshman Practice Schedule")
   - For game pages only: subhead with MaxPreps CTA `"Live scores and stats →"` opening `site_settings.maxpreps_team_url` in a new tab

2. **Game | Practice toggle** (single-row segmented control)
   - Pill-shaped two-button segmented control beneath the page header
   - Two buttons: `Game` (default, leftmost) and `Practice`
   - Active button: filled green with white text
   - Inactive button: outlined green with green text (same size, same shape)
   - Clicking toggles between `/schedule/games/[level][/designation]` and `/schedule/practice/[level]` for the current team
   - Practice route never carries designation: clicking Practice from `/schedule/games/freshman/green` or `/schedule/games/freshman/blue` lands on `/schedule/practice/freshman`
   - **No memory across team switches.** Switching teams via the header dropdown always lands on the Game view; the Game/Practice selection does not persist.

### Terminology

Use **Game** (singular) and **Practice** (singular) consistently. Never "Games" or "Practices." Applies to:
- The segmented control labels
- Page titles
- All copy in nav, buttons, headings, and empty states

### Game rendering

For each game page (`/schedule/games/[level]` or `/schedule/games/freshman/[designation]`):

**Query:**
```sql
SELECT * FROM games
WHERE year = :current_year
  AND team_level = :level
  AND COALESCE(team_designation, '') = COALESCE(:designation, '')
ORDER BY game_date ASC;
```

Notes:
- For varsity/jv, `:designation` is NULL (matches NULL in DB via the COALESCE pattern)
- For freshman/green, `:designation` is `'Green'`
- For freshman/blue, `:designation` is `'Blue'`
- URL segments are lowercase; map to title-case before binding

**Table columns:** Date | Opponent | Location | Home/Away | Time | Result | Watch

**Per-row rendering:**
- Date: `game_date` formatted as e.g. "Fri, Sep 4"
- Opponent: `opponent` text; if `opponent_url` is set, wrap in a link
- Location: `location`; if `location_url` is set, wrap in a link (opens new tab)
- Home/Away: badge or label, e.g. "HOME" or "AWAY" or "NEUTRAL"
- Time: `game_date` formatted as e.g. "7:30pm"
- Result column behavior:
  - `result_status = 'final'` and both scores present: render "W 35-14" if `our_score > their_score`, "L 21-28" if not, "T 14-14" if equal
  - `result_status = 'scheduled'`: `—`
  - `result_status = 'cancelled'`: "Cancelled" badge
  - `result_status = 'postponed'`: "Postponed" badge
  - `result_status = 'tbd'`: "TBD"
- Watch column: external-link icon (lucide) linking to `watch_url` if present, opens new tab; empty otherwise
- Notes: if `notes` is non-empty, render as a small subtitle row beneath the matchup row (e.g., "Homecoming", "Senior Night", "Scrimmage")

**Visual treatment per content_map_v2 open question:** light background tint on home-game rows. Apply.

**Empty state:** card showing "[Level] [designation if any] game schedule coming soon. Check MaxPreps for current details." with a MaxPreps button.

**Freshman designation in user-facing copy.** Page titles and empty-state copy on `/schedule/games/freshman/[designation]` only include the designation word ("Green" or "Blue") when `site_settings.freshman_has_blue = true`. When the flag is false, the title reads "{year} Freshman Game Schedule" and the empty-state copy reads "Freshman game schedule coming soon..." with no "Green." URL routing is unchanged (`/freshman/green` always renders, `/freshman/blue` 404s when the flag is false). This matches the header dropdown convention from § 4.5 line 107: the Green substructure is invisible to users when there is no Blue.

**Mobile (<768px):** tables collapse to cards. Each card = matchup, date, time, location, home/away badge, result, watch icon. Do not attempt to fit the 7-column table on a 375px viewport.

### Practice rendering

For each practice page (`/schedule/practice/[level]`):

**Query:**
```sql
SELECT * FROM practice_schedules
WHERE year = :current_year
  AND team_level = :level
  AND active = true
LIMIT 1;
```

**Render:**
- If row exists and `body` is non-empty: render markdown body
- If row exists and `body` is empty: render `source_note` value (seeded to "Awaiting schedule from coaching staff") inside an empty-state card
- If no row at all: same empty-state card with default copy "Practice schedule coming soon."

No table. Practice is a markdown blob, not structured rows.

**Freshman practice title when `freshman_has_blue = true`.** Practice is a single shared row across Green and Blue (no `team_designation` column on `practice_schedules`). On `/schedule/practice/freshman`, when the flag is true, the page title reads "{year} Freshman Green & Blue Practice Schedule" to signal the shared scope. When the flag is false, the title stays "{year} Freshman Practice Schedule." Varsity and JV practice titles are unchanged in both modes.

### Edge cases

- `freshman_has_blue` is toggled from true to false while a visitor has `/schedule/games/freshman/blue` open: behavior on next nav is 404; current page render is whatever the user last loaded. Acceptable.
- **NULL `team_designation` on a freshman row:** the query uses strict matching (`COALESCE(team_designation, '') = COALESCE(:designation, '')`). NULL freshman rows match no public URL and do not render. This is intentional. The admin spec will require the field at entry time (default to Green when `freshman_has_blue = false`, force a Green/Blue picker when true; uploads must include the column when blue is configured). NULL rows are a data-entry mistake to be caught by the admin UI, not papered over by the render layer.

---

## 6. Deliverable C: Roster routes

### Route map (Commit B scope)

| Path | Behavior |
|---|---|
| `/roster` | 301 redirect to `/roster/varsity` |
| `/roster/varsity` | Renders varsity roster |
| `/roster/jv` | Renders JV roster |
| `/roster/freshman` | 404 |
| `/roster/freshman/green` | Renders (always present) |
| `/roster/freshman/blue` | If `freshman_has_blue = true`, renders; else 404 |
| `/roster/varsity/[anything]` | 404 |
| `/roster/jv/[anything]` | 404 |

### Header navigation

Roster navigation lives in the main site header as a dropdown menu, mirroring the Schedule dropdown structure (see Section 5). Same team list, same click-to-open behavior:

When `freshman_has_blue = false`:
- Varsity → `/roster/varsity`
- JV → `/roster/jv`
- Freshman → `/roster/freshman/green`

When `freshman_has_blue = true`:
- Varsity → `/roster/varsity`
- JV → `/roster/jv`
- Freshman Green → `/roster/freshman/green`
- Freshman Blue → `/roster/freshman/blue`

### Shared layout

`app/roster/layout.tsx`. Renders:

1. **Page header**
   - Title: `[current_year] [Level] Roster` (e.g., "2026-27 Varsity Roster")

2. **No in-page tab nav.** Roster has only one view per team. Team selection happens via the main header dropdown.

### Roster rendering

**Queries** (two queries per page, or one with join):
```sql
-- 1. Find the roster row
SELECT * FROM rosters
WHERE year = :current_year
  AND team_level = :level
  AND COALESCE(team_designation, '') = COALESCE(:designation, '')
  AND active = true
LIMIT 1;

-- 2. If roster found, fetch its players
SELECT * FROM players
WHERE roster_id = :roster_id
  AND active = true
ORDER BY sort_order ASC, jersey_number ASC NULLS LAST;
```

**Render rules** (per `schema_v2_addendum.md` Section 2):
- If no roster row exists: empty-state card "2026-27 [level] roster coming soon."
- If roster exists and `body` is non-empty: render markdown body above the player table
- If players exist: render structured table
- If both exist: body is preamble, table is data
- If roster exists but no body and no players: empty-state with the roster's `source_note` if set

**Table columns:** Jersey # | Name | Position | Grade | Height | Weight

- Jersey #: `jersey_number` as text (handles "00")
- Name: `first_name last_name`
- Position, Grade, Height: render as stored; `—` if NULL
- Weight: render as `[n] lbs`; `—` if NULL

**Sort:** `sort_order ASC` primary, then numeric jersey number ascending when sort_order ties. When jersey is non-numeric (rare), fall back to lexicographic. Render order matches the DB order from the query.

**Mobile (<768px):** table collapses to cards. Each player card shows all columns: `#Jersey  FirstName LastName` on row 1, `Position · Grade` on row 2, `Height · Weight lbs` on row 3. The "how big is that dude" sideline use case earns the third row.

**Privacy note:** these pages list minors. RLS already enforces `rosters.active = true` and `players.active = true` through the subquery (per addendum 2). If the data does not appear publicly, double-check RLS before debugging anywhere else.

### Edge case

A player row exists where the parent roster has `active = false`: RLS hides it. Public page renders as if the player did not exist. Expected.

---

## 7. Deliverable D: Coaches route

### Route

| Path | Behavior |
|---|---|
| `/coaches` | Single page, all sections per `role_category` |
| `/coaches/[anything]` | 404 |

### Page structure

Per `content_map_v2.md`:

1. **Page header**
   - Title: "Coaches & Trainers"
   - Subhead: `[current_year]`

2. **Head Coach section**
   - Query rows where `role_category = 'head'` and `active = true` and `year = :current_year`
   - If 1+ rows: render coach cards
   - If 0 rows: render placeholder card with copy: "Head Coach: position currently open. We'll update this page when the new coach is announced."
   - Do **not** name Cruz. The seed does not include a head coach row; do not add one in Commit B.

3. **Coordinators section**
   - `role_category = 'coordinator'`, active, current year, ordered by `sort_order ASC`
   - Hide section heading entirely if zero rows

4. **Position Coaches section**
   - `role_category = 'position_coach'`, same filters and ordering
   - Coach Wallin shows up here per the seed

5. **Trainers section**
   - `role_category = 'trainer'`

6. **Staff section**
   - `role_category = 'staff'`

### Coach card

Each card renders:
- Photo: `photo_url` if set; default avatar block (silhouette or initials) otherwise
- Name (h3)
- Role (e.g., "Defensive Coordinator")
- Email: `mailto:` link if set
- Phone: `tel:` link if set
- Bio: markdown rendered with safe HTML; hide if empty

**Layout:** 2-3 cards per row on desktop, 1 per row on mobile. Within each section.

### Query

```sql
SELECT * FROM coaches
WHERE year = :current_year
  AND active = true
ORDER BY
  CASE role_category
    WHEN 'head' THEN 1
    WHEN 'coordinator' THEN 2
    WHEN 'position_coach' THEN 3
    WHEN 'trainer' THEN 4
    WHEN 'staff' THEN 5
  END,
  sort_order ASC;
```

Builder can also do one query per section if preferred. Single query and group in code is fewer round-trips and fine at this scale.

### Empty state

If the entire table returns zero rows for the year: render only the page header + the "Head Coach: position currently open" placeholder. Do not render the other section headings.

---

## 8. Deliverable E: Resources route

### Route

| Path | Behavior |
|---|---|
| `/resources` | Single page, section-per-`resource_section` enum value |
| `/resources/[anything]` | 404 |

### Page structure

Per `content_map_v2.md`:

1. **Page header**
   - Title: "Forms & Links"
   - Subhead: "Forms, links, and resources for the McNeil Mavericks football community"

2. Sections, in this order (enum order):
   - **Registration & Forms** (`section = 'registration_forms'`)
   - **Communications** (`section = 'communications'`)
   - **Resources** (`section = 'resources'`)
   - **Stadiums & Directions** (`section = 'stadiums'`)
   - **Other** (`section = 'other'`)

3. Each section:
   - Heading
   - List of `resource_links` rows ordered by `sort_order ASC`
   - Each item: clickable label (linking to `url`, opens new tab if external), description below in smaller text, icon based on `icon_hint`
   - Hide section heading if zero rows in that section

### Query

Single query, group in code:
```sql
SELECT * FROM resource_links
WHERE active = true
ORDER BY section, sort_order ASC;
```

### Icon mapping

Frontend maps `icon_hint` values to lucide icons:
- `external` → ExternalLink
- `pdf` → FileText
- `form` → ClipboardList
- `video` → Play
- Anything else (including NULL) → ExternalLink as fallback

### Link behavior

- URLs starting with `http://` or `https://`: open in new tab with `rel="noopener noreferrer"`
- URLs starting with `/`: same-tab navigation
- All other values: treat as external, open in new tab

### Empty state

If the entire table is empty: render "Resources coming soon. Contact boosters@mcneilmavericks.org with questions." in a card.

---

## 9. Shared concerns

### Data fetching pattern

Server components. No client-side fetching for any of these pages. Page receives data at render time from the Supabase server client, which uses the anon key and goes through RLS.

### Caching strategy

**Dynamic rendering.** No `revalidate` directive on any Commit B page; let App Router default to dynamic when pages fetch data through RLS. Every request hits Postgres.

Rationale: traffic is small enough that the cost is negligible, and the use case favors freshness (admin updates a score after a game, visitor refreshes and sees it immediately). If page load becomes noticeably slow later, switch to `revalidate: 60` per page. One-line change, no rollback needed.

### Type safety

Generate Supabase types after Commit A applied: `supabase gen types typescript --project-id rgdoolafpvhtsdpxbqvj > lib/database.types.ts`. Use throughout Commit B. The CC migration workflow already covers this; just confirm types are current.

### Error handling

- Database error during render: render a clean error state ("Something went wrong loading this page. Please try again.") rather than a crash. Log to Vercel.
- Missing `site_settings` row: this should never happen given the seed, but if it does, the page should not crash. Treat as if `current_year` is `'2026-27'` (literal fallback in the helper) and freshman_has_blue is false. Log loudly.

### Accessibility

- All nav controls are keyboard-navigable (arrow keys to move between options, Enter to activate)
- Header dropdowns and the Game/Practice toggle announce active state to screen readers (`aria-current="page"` where applicable, `aria-expanded` on dropdown triggers)
- Coach photos have `alt` text built from name + role ("Coach Wallin, Position Coach")
- Avatar placeholders have `alt=""` (decorative)
- Tables have proper `<th>` headers with `scope="col"`

Lighthouse pass is Step 14, not Commit B. Get the basics right now so Step 14 is cleanup, not rework.

### RLS sanity

After Commit B is on staging, hit each route as an anonymous user (incognito tab):
- All Commit B routes load and render
- No row returns 0 due to a missing RLS policy when the data is present
- The `players` table specifically: anon SELECT must work through the subquery on `rosters.active`

If a page renders empty when seed data exists, RLS is the first place to look. Re-read `schema_v2_addendum.md` Section 3.

### Mobile

Each page works at 375px. Verify on iPhone-sized viewport before declaring done. Reuse Tailwind responsive prefixes consistently with whatever Step 4b chose.

### Linking back

Header nav from Step 4b already points to `/schedule`, `/roster`, `/coaches`, and `/resources` (label "Forms & Links"). Verify all four resolve after Commit B. The other top-level nav items (`/news`, `/sponsors`, `/boosters/*`) remain 404 or partial; that's fine and explicitly out of scope.

### Print

Schedule (games + practice) and roster pages get print support. Coaches and resources do not.

**Print button:** small button in the page header area, lucide `Printer` icon, label "Print." Calls `window.print()`. That's it. The browser's print dialog already includes "Save as PDF" as a destination on every platform; no need for a separate PDF generator.

**Print stylesheet:** `@media print` block (or Tailwind `print:` prefixes) that:
- Hides: header nav (including dropdowns), footer, on-page Game/Practice toggle, the Print button itself, the MaxPreps button, any other action buttons
- Shows: page title (rendered as a real h1 with the year + level), the data (game table, roster table, or practice markdown body), a small footer line with the page URL and the print date
- Forces the data table to render as a real table even at mobile widths (the mobile-card layout is unusable on paper)
- Removes background tints and colored badges; uses black-on-white with bold for emphasis
- Sets a sensible page margin

**Acceptance:** open print preview on `/schedule/games/varsity`, `/schedule/practice/freshman`, and `/roster/varsity` with seed data plus one or two test rows. The result should be a clean printable page with the title, the data, and nothing else. Cancel without printing.

**Scope:** schedule and roster only. Coaches: nobody prints a coaches page. Resources: it's a list of links, useless on paper.

---

## 10. Acceptance criteria

Commit B is done when all of the following are true on the Vercel preview deploy:

**Code swap:**
- [ ] `grep -r "2026-27" app/ components/ lib/` returns no matches in TS/TSX (SQL files in `db/` are excluded)
- [ ] Changing `site_settings.current_year` in Supabase and revalidating shows the new value on every page within 60 seconds

**Header + Footer (pre-Schedule work):**
- [ ] Schedule dropdown in main header opens on click, lists `Varsity / JV / Freshman` (or `Varsity / JV / Freshman Green / Freshman Blue` when `freshman_has_blue = true`)
- [ ] Roster dropdown in main header opens on click with the same team list as Schedule
- [ ] Each dropdown item navigates directly to that team's page (no intermediate hub page)
- [ ] Footer renders as a slim band: site links horizontal in a single row, address column tightened, disclaimer + copyright combined into a single paragraph at the bottom
- [ ] Vertical footer height roughly halved compared to the previous Step 4b footer

**Schedule:**
- [ ] `/schedule` 301s to `/schedule/games/varsity`
- [ ] `/schedule/games/varsity`, `/schedule/games/jv`, `/schedule/games/freshman/green`, `/schedule/practice/varsity`, `/schedule/practice/jv`, `/schedule/practice/freshman` all render (empty states OK)
- [ ] `/schedule/games/freshman` returns 404
- [ ] `/schedule/games/varsity/anything` returns 404
- [ ] `/schedule/games/freshman/blue` returns 404 when `freshman_has_blue = false`
- [ ] Toggling `freshman_has_blue = true` in DB and revalidating: `Freshman Green` and `Freshman Blue` appear in both header dropdowns, `/schedule/games/freshman/blue` and `/roster/freshman/blue` render
- [ ] MaxPreps CTA in schedule header opens `site_settings.maxpreps_team_url` in new tab
- [ ] Practice pages render the seeded `source_note` as empty state copy
- [ ] On-page Game/Practice toggle: clicking Practice from `/schedule/games/freshman/green` lands on `/schedule/practice/freshman` (drops the designation)
- [ ] On-page Game/Practice toggle: switching teams via header dropdown always lands on Game view, regardless of prior Game/Practice selection
- [ ] Active toggle button is filled green; inactive toggle button is outlined green; both same size and shape
- [ ] Page titles and all visible copy use "Game" and "Practice" singular (never "Games" or "Practices")
- [ ] Schedule routes that 404 inside the schedule tree (e.g., before all pages are built) still render the main header and footer (via `not-found.tsx`)

**Roster:**
- [ ] `/roster` 301s to `/roster/varsity`
- [ ] `/roster/varsity`, `/roster/jv`, `/roster/freshman/green` all render
- [ ] `/roster/freshman` returns 404
- [ ] Inserting a test player row via Supabase Studio (one player on varsity) and revalidating: player appears in the table
- [ ] Removing that test row before declaring done

**Coaches:**
- [ ] `/coaches` renders with the "Head Coach: position currently open" placeholder
- [ ] Coach Wallin appears in the Position Coaches section
- [ ] No other sections render headings until rows exist

**Resources:**
- [ ] `/resources` renders with whatever sections have seeded rows
- [ ] SportsYou and other seeded links resolve correctly
- [ ] External links open in new tabs

**Print:**
- [ ] Print button visible on `/schedule/games/*`, `/schedule/practice/*`, and `/roster/*` pages
- [ ] Cmd-P (or button click) on `/schedule/games/varsity` produces print preview with title + table + no nav/footer/buttons
- [ ] Same check on `/roster/varsity` and `/schedule/practice/freshman`
- [ ] "Save as PDF" from the print dialog produces a usable PDF
- [ ] No Print button on `/coaches` or `/resources`

**General:**
- [ ] No console errors on any of the routes
- [ ] All pages render at 375px width without horizontal scroll
- [ ] Anon visitor (incognito) sees the same content as a content_admin visitor for all Commit B pages
- [ ] Vercel preview deploy succeeds; no build warnings introduced by Commit B

---

## 11. Rollback

Commit B is reversible at the commit level. If any subset is broken at cutover:

1. **Per-route rollback:** revert the specific route file(s) in Git. Header nav links to that route resume 404'ing (the Step 4b state). Cleaner than half-shipped renders.

2. **Full Commit B rollback:** `git revert` the Commit B merge. Site returns to Step 4b state. Schema (Commit A) stays applied; the schema work was always intended to outlive any single rendering pass.

3. **current_year swap rollback:** if the helper has a bug, set `site_settings.current_year` to whatever the literal was (`'2026-27'`) and the user-facing display stays correct while you fix the bug. Hardcode is not the answer; ship the fix.

No database rollback is needed; Commit B is read-only and adds no data.

---

## 12. Decisions (locked)

| # | Decision | Resolution | Locked |
|---|---|---|---|
| 1 | Caching strategy | Dynamic. No `revalidate` directive. Fresh data every request. | 2026-05-16 |
| 2 | NULL freshman row handling | Strict. No render-layer fallback. Admin UI enforces the field at entry. | 2026-05-16 |
| 3 | Print support | Print button + print stylesheet on schedule (games + practice) and roster pages. Coaches and resources excluded. | 2026-05-16 |
| 4 | Home-game visual treatment | Apply light background tint to home-game rows. | 2026-05-16 |
| 5 | Height/weight on mobile roster | Show all columns. The sideline use case justifies the third row. | 2026-05-16 |
| 6 | `getCurrentYear()` helper location | Builder's call. Recommend `lib/site-settings.ts` returning the full settings object. | 2026-05-16 |
| 7 | Build order within Commit B | A (current_year) → A.5 (header dropdowns + footer) → B (Schedule) → C (Roster) → D (Coaches) → E (Resources), one commit per slice. | 2026-05-16 |
| 8 | Team selection UX | Header dropdown (modeled on Boosters dropdown), not in-page tab nav. Applies to both Schedule and Roster. Each item lands directly on the team's page. Click-to-open. | 2026-05-17 |
| 9 | Freshman dropdown structure when `freshman_has_blue = true` | Flat: `Varsity / JV / Freshman Green / Freshman Blue` (4 items). No nested submenu. | 2026-05-17 |
| 10 | Game vs Practice toggle | On-page segmented control (pill-shaped, two buttons). Active = filled green. Inactive = outlined green. No sticky 3-row nav. | 2026-05-17 |
| 11 | Game/Practice memory across team switches | None. Switching teams from header always lands on Game view. | 2026-05-17 |
| 12 | Terminology | "Game" and "Practice" (singular). Never "Games" or "Practices." Applies everywhere. | 2026-05-17 |

**Admin UX implications captured for the admin spec** (not Commit B work, but recorded here so they don't get lost):
- When `freshman_has_blue = false`: designation defaulted to Green by the admin UI, never shown.
- When `freshman_has_blue = true`: admin picks Green or Blue once per session/context, then enters players within that context. Default selection state is "Select" (forces an explicit choice).
- Players can be moved Green ↔ Blue via an explicit "swap team" action. Identity preserved; no delete-and-recreate.
- Bulk upload behavior: if `freshman_has_blue = true`, the upload file must include a Green/Blue column; error on missing. If false, default to Green silently.
- Same-name collisions across teams: not enforced as unique. Jersey number disambiguates visually.

---

## 13. Estimate

Per CLAUDE.md: 2-3 evenings.

Rough breakdown:
- Current_year swap: 30 min (done 2026-05-16)
- Header dropdowns + footer rework + cleanup of obsolete sticky nav: half evening
- Schedule layout + 7 routes: 1 evening
- Roster layout + 5 routes: half evening
- Coaches: half evening
- Resources: half evening
- Print buttons + stylesheets (schedule + roster): 1-2 hours
- Mobile pass + acceptance criteria walkthrough: half evening

Total: ~3-4 evenings. The header/footer rework adds half an evening but removes the three-row sticky nav and unblocks the simpler Schedule and Roster layouts. Net effect on total time: small. If it stretches past 5 evenings, scope creep is happening; stop and re-spec.

---

## 14. What comes after Commit B

Per `build_plan_v2.md`, the next planned slice is Step 6 (joins/payments) or Step 7a (Tier A admin CRUD), depending on Jeremy's priority. Track A items (J6, J12, J13) also live in parallel.

The remaining public routes (`/news`, `/sponsors`, `/boosters/*` updates) are their own slice and not yet specced as a single commit. Likely Commit C, drafted after Commit B ships.

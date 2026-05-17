# Schema + Content Map — Addendum 2

Written 2026-05-16. Reads with `schema_v2.md`, `schema_v2_addendum.md`, `content_map_v2.md`. Covers Jeremy's round-2 feedback on the content map's open questions plus structural changes (practice schedules, team subdivisions, split URLs).

---

## Confirmed answers

| # | Question | Decision |
|---|---|---|
| 1 | Tier perks on `/sponsors`? | **No** — perks live only on `/boosters/sponsor` |
| 2 | Player photos on roster? | **No Phase 1**. Phase 2 maybe stats (not photos) from coaches, with an admin-toggleable on/off |
| 3 | Sponsorship flow A vs B | **A** — inquiry form, manual follow-up. Adding `sponsorship_inquiries` table below |
| 4 | Quick Links icons | **Yes**, lucide-react icons on each card |
| 5 | `volunteer@` alias | **Skip**, route through `boosters@` |
| 6 | X/Twitter in footer | **Add**, but not MVP-blocking. Football X + boosters X + Facebook all real |

Plus a couple of net-new directional notes:
- **Multi-sport future**: links to other sports' booster sites now; possibly host other sports on this domain later (e.g., `/baseball`). Phase 1 architectural impact: none. Phase 1 won't include this; URL paths chosen to not paint into a football-only corner.
- **Donate and join stay separate** (confirms current spec).
- **Schedule and events stay separate** (confirms current spec).
- **Scrimmages go on the game schedule**, not on a separate scrimmage track. They're `games` rows with `notes = 'Scrimmage'` (or similar).

---

## 1. New table: sponsorship_inquiries

For Option A: sponsor prospects fill out a form, the booster club (Kendra) follows up manually. No automatic Stripe charge.

```sql
CREATE TYPE sponsorship_inquiry_status AS ENUM ('new', 'in_progress', 'closed_won', 'closed_lost');

CREATE TABLE sponsorship_inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text NOT NULL,
  contact_name text NOT NULL,
  contact_email text NOT NULL,
  contact_phone text,
  tier_id uuid REFERENCES sponsorship_tiers(id) ON DELETE SET NULL,
  message text,
  logo_url text,
  status sponsorship_inquiry_status NOT NULL DEFAULT 'new',
  notes text,
  year text NOT NULL,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_sponsorship_inquiries_status_created ON sponsorship_inquiries(status, created_at DESC);
CREATE INDEX idx_sponsorship_inquiries_year ON sponsorship_inquiries(year);

CREATE TRIGGER touch_sponsorship_inquiries BEFORE UPDATE ON sponsorship_inquiries
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

**Design notes:**
- `logo_url` is optional. If sponsor uploads at inquiry time, we store it in the `sponsor-logos` Storage bucket. If they don't, Kendra collects later and admin uploads via Step 13 CRUD.
- `notes` is admin-facing for Kendra to track call notes, contract status, etc.
- When status flips to `closed_won`, admin manually creates a `sponsors` row and a `payments` row separately. We don't auto-create on status change — keeps the data lineage clean and lets admin handle invoicing/contracts however the booster club operates.
- `year` because some inquiries come in months ahead for the next season; needs to be tagged to the right cycle.

**RLS:**

```sql
ALTER TABLE sponsorship_inquiries ENABLE ROW LEVEL SECURITY;

-- No anon access. Form posts to /api/sponsorship/create (server-side, service role).

CREATE POLICY "Content admins read sponsorship inquiries" ON sponsorship_inquiries
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write sponsorship inquiries" ON sponsorship_inquiries
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update sponsorship inquiries" ON sponsorship_inquiries
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete sponsorship inquiries" ON sponsorship_inquiries
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
```

Same anon-can't-write pattern as `memberships`: form submission goes through a server-side API route running as service role.

**Form submission flow** (for `/boosters/sponsor`):

- POST to `/api/sponsorship/create` with form payload
- Server validates with Zod, optionally uploads logo to `sponsor-logos` bucket
- Server creates `sponsorship_inquiries` row with `status = 'new'`
- Server sends email via Resend to `sponsorship@mcneilmavericks.org` (or `boosters@` until aliases live) with the inquiry summary + a link to the admin UI
- Returns success; UI shows confirmation message

---

## 2. Schema modification: team_designation column

Jeremy: "Freshman might have Blue and Green teams too." Adding a `team_designation` column to handle subdivisions within a `team_level`. Stony Point had Freshman Gold/Blue/Combined with this pattern — works in the wild.

**Add to `games`:**

```sql
ALTER TABLE games
  ADD COLUMN team_designation text;

CREATE INDEX idx_games_year_team_designation_date
  ON games(year, team_level, team_designation, game_date);
```

**Add to `rosters`:**

```sql
ALTER TABLE rosters
  ADD COLUMN team_designation text;

-- Replace the old UNIQUE (year, team_level) constraint:
ALTER TABLE rosters DROP CONSTRAINT rosters_year_team_level_key;
CREATE UNIQUE INDEX idx_rosters_unique_team_designation
  ON rosters (year, team_level, COALESCE(team_designation, ''));
```

The `COALESCE(team_designation, '')` in the unique index treats NULL as "the main/only team for this level," so:
- Varsity, JV → `team_designation IS NULL` (one row each per year)
- Freshman with no subdivision → `team_designation IS NULL`
- Freshman Blue + Freshman Green → two rows, designation = `'Blue'` and `'Green'`

**Design notes:**

- `team_designation` is **nullable** by intent. NULL means "the canonical team for this level." Specific values are subdivision names like `'Blue'`, `'Green'`, `'Combined'`.
- Not adding to `players` because players already FK to `rosters`, which carries the designation.
- Not adding to `coaches` because coaching staff typically serves across subdivisions (one defensive coordinator for all of freshman, not one per Blue/Green).
- Not adding to `practice_schedules` directly — they get it via the same column structure (see below).

**Display rules:**

- If only one row exists per `team_level` for a year (designation NULL), display simply as "Varsity" / "JV" / "Freshman."
- If multiple designations exist for one `team_level`, display as "Freshman Blue" / "Freshman Green" etc.
- A "Freshman Combined" view (showing all freshman rosters/games merged) is **not** automatically generated. If we want that, admin creates a row with `team_designation = 'Combined'` and manually maintains it (Stony Point did this; not free).

**Phase 1 expectation:** McNeil probably has just `varsity`, `jv`, `freshman` (NULL designation). The Blue/Green capability is wired in but the rows don't exist until a coach actually subdivides.

---

## 3. New table: practice_schedules

Practice schedules are real and parents want them. Today they're stale on the SE site ("Practice Sched - 10/29/24"). Going forward: simple markdown body per team, admin updates as the coach sends them.

Choosing **table over** other options because:
- Single field on `site_settings` per team gets ugly fast (3+ team levels, possible subdivisions)
- A field on `rosters.body` mixes concepts (roster ≠ schedule)
- A separate small table is admin-friendly: one CRUD per team, clear ownership

```sql
CREATE TABLE practice_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,
  team_level team_level NOT NULL,
  team_designation text,                       -- NULL for "main" team
  body text NOT NULL DEFAULT '',               -- markdown
  source_note text,                            -- "Provided by Coach X on YYYY-MM-DD"
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_practice_schedules_unique
  ON practice_schedules (year, team_level, COALESCE(team_designation, ''));
CREATE INDEX idx_practice_schedules_year_active
  ON practice_schedules (year, active);

CREATE TRIGGER touch_practice_schedules BEFORE UPDATE ON practice_schedules
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

**RLS:** same pattern as rosters.

```sql
ALTER TABLE practice_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads active practice schedules" ON practice_schedules
  FOR SELECT TO anon USING (active = true);

CREATE POLICY "Authenticated read all practice schedules" ON practice_schedules
  FOR SELECT TO authenticated USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write practice schedules" ON practice_schedules
  FOR INSERT TO authenticated WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update practice schedules" ON practice_schedules
  FOR UPDATE TO authenticated USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete practice schedules" ON practice_schedules
  FOR DELETE TO authenticated USING (current_user_has_role('content_admin'));
```

**Seed:** three empty stubs like rosters.

```sql
INSERT INTO practice_schedules (year, team_level, source_note) VALUES
  ('2026-27', 'varsity',  'Awaiting schedule from coaching staff'),
  ('2026-27', 'jv',       'Awaiting schedule from coaching staff'),
  ('2026-27', 'freshman', 'Awaiting schedule from coaching staff');
```

**Why not a structured calendar of individual practice events?** Coaches publish practice schedules as static documents ("Mon-Thu 4-6pm, padded practice Tues+Thurs, Fri walkthrough"), not as individual calendar entries. Capturing them as markdown body matches what we'll actually get. If a coach later wants per-day specific events, we add a `practice_events` table at that point.

---

## 4. URL structure — split by team level

Replacing the single-page `/schedule` and `/roster` from `content_map_v2.md` with split URLs per Jeremy's spec. Each becomes a real page.

### Schedule URLs

```
/schedule                            → defaults to /schedule/games/varsity
/schedule/games/varsity              → varsity games
/schedule/games/jv                   → JV games
/schedule/games/freshman             → freshman games (designation NULL)
/schedule/games/freshman/blue        → freshman Blue games (only if rows exist with designation='Blue')
/schedule/games/freshman/green       → freshman Green games (only if rows exist with designation='Green')
/schedule/practice/varsity           → varsity practice
/schedule/practice/jv                → JV practice
/schedule/practice/freshman          → freshman practice
/schedule/practice/freshman/blue     → only if applicable
```

**Page structure** — every schedule page has the same shell:

1. Page header: title ("2026-27 Varsity Schedule" or "2026-27 Freshman Practice"), MaxPreps CTA (for game pages only)
2. Sticky secondary nav at the top with three tab rows:
   - Type: **Games | Practice**
   - Level: **Varsity | JV | Freshman**
   - Designation (only renders when more than one exists for the current level): **Main | Blue | Green | …**
3. Content area: schedule table (games) or markdown body (practice)
4. Empty state if no rows

**Routing logic in Next.js (App Router):**

```
app/schedule/page.tsx                          → redirect to /schedule/games/varsity
app/schedule/games/[level]/page.tsx            → dynamic, with [level] = varsity|jv|freshman
app/schedule/games/[level]/[designation]/page.tsx  → dynamic for subdivisions
app/schedule/practice/[level]/page.tsx
app/schedule/practice/[level]/[designation]/page.tsx
```

**Per-page data queries:**

Games page:
```sql
SELECT * FROM games
WHERE year = :current_year
  AND team_level = :level
  AND (
    (:designation IS NULL AND team_designation IS NULL)
    OR (:designation IS NOT NULL AND team_designation = :designation)
  )
ORDER BY game_date ASC;
```

Practice page:
```sql
SELECT * FROM practice_schedules
WHERE year = :current_year
  AND team_level = :level
  AND active = true
  AND COALESCE(team_designation, '') = COALESCE(:designation, '')
LIMIT 1;
```

### Roster URLs

Mirror the schedule pattern:

```
/roster                          → defaults to /roster/varsity
/roster/varsity
/roster/jv
/roster/freshman
/roster/freshman/blue            → if subdivisions
/roster/freshman/green
```

Same sticky tab nav at the top. Same display logic from `content_map_v2.md` (optional body markdown → structured player table → empty state).

### What stays single-page

- `/coaches` stays single page with sections per `role_category`. Coaches generally serve across team levels.
- `/news`, `/sponsors`, `/resources`, `/boosters/*` — unchanged.

---

## 5. Footer — social media slot

Per Jeremy's note: not MVP-blocking, but real. Updating site_settings:

```sql
ALTER TABLE site_settings
  ADD COLUMN facebook_football_url text,
  ADD COLUMN x_football_url text,
  ADD COLUMN facebook_boosters_url text,
  ADD COLUMN x_boosters_url text;
```

Already have `facebook_group_url`, `instagram_url`, `youtube_url` from earlier. Renaming `facebook_group_url` → `facebook_boosters_url` for consistency. The football accounts get their own fields.

Actually let me reconsider — six fields for socials is a lot. Going with a simpler structure: keep separate columns for the actively-used accounts only, in this order: `facebook_football_url`, `facebook_boosters_url`, `x_football_url`, `x_boosters_url`, `instagram_url`, `youtube_url`.

**Footer rendering rules:**
- Group by audience: Football icons (FB/X for football) on the left of the social row, Boosters icons (FB/X for boosters) on the right
- Or simpler: one merged row of icons. Each icon shows a tooltip on hover ("Mavs Football on Facebook", "Boosters on X").
- Each icon hides if its URL field is null

My pick: merged row, tooltips. Cleaner footer. Footer label says "Follow McNeil Mavericks Football" above the icons.

**Phase 1 expectation:** populate from Jeremy's notes — football Facebook (per the Cruz announcement post, this exists), football X (need URL), boosters X (need URL), boosters Facebook (need URL). Skip Instagram + YouTube unless confirmed. None of these block launch.

---

## 6. Multi-sport future — note only

Jeremy: "links to other sports too probably at some point and maybe even add other sports to our page later. like `/baseball`."

Two separate things:

A. **Outbound links to other sports' booster sites** — link out, don't host. Add a section to `/resources` called "Other Mavericks Sports" with curated links once Jeremy has them.

B. **Hosting other sports on this domain later** — adds `sport` column to games, rosters, coaches, news, sponsors. NOT doing in Phase 1; document the migration path:

> Future migration: `ALTER TABLE games ADD COLUMN sport text NOT NULL DEFAULT 'football'`. Same for rosters, coaches, news, sponsors. Update RLS and queries to filter by sport. Update URL routing to namespace by sport (`/football/schedule/games/varsity`, `/baseball/schedule/games/varsity`). One weekend of work when the second sport actually arrives.

**Phase 1 architectural commitment:** URL paths are not football-specific. `/schedule`, `/roster`, `/coaches` work whether we have one sport or three. When a second sport arrives, current paths become football paths (redirect) and new sport paths get added.

---

## 7. Updated migration order

Following `schema_v2_addendum.md` numbering:

```
011_football_pivot_types.sql          (5 enums from schema_v2)
012_football_pivot_tables.sql         (games, rosters, coaches, resource_links)
013_players_table.sql                 (from schema_v2_addendum)
014_site_settings_additions.sql       (from schema_v2)
015_football_pivot_triggers.sql
016_football_pivot_rls.sql
017_players_rls.sql                   (from schema_v2_addendum)
018_football_pivot_seed.sql

NEW additions from this addendum:
019_team_designation.sql              (ALTER games, rosters; drop+recreate rosters unique)
020_practice_schedules.sql            (table + index + trigger)
021_practice_schedules_rls.sql
022_sponsorship_inquiries.sql         (type + table + index + trigger + RLS)
023_site_settings_socials.sql         (ALTER site_settings, rename column)
024_practice_schedules_seed.sql       (3 empty stubs)
```

---

## 8. Updated route map summary

Replaces the route map in `content_map_v2.md`:

| URL | Purpose | Notes |
|---|---|---|
| `/` | Home | unchanged |
| `/schedule` | redirect → `/schedule/games/varsity` | new |
| `/schedule/games/[level]` | Games for a team level | new pattern |
| `/schedule/games/[level]/[designation]` | Games for a subdivision (Freshman Blue) | new, conditional |
| `/schedule/practice/[level]` | Practice schedule for a team level | new |
| `/schedule/practice/[level]/[designation]` | Practice for a subdivision | new, conditional |
| `/roster` | redirect → `/roster/varsity` | new |
| `/roster/[level]` | Roster for a team level | new pattern |
| `/roster/[level]/[designation]` | Roster for a subdivision | new, conditional |
| `/coaches` | unchanged | |
| `/news` + `/news/[slug]` | unchanged | |
| `/sponsors` | unchanged | |
| `/resources` | unchanged | will get "Other Mavericks Sports" section once Jeremy adds links |
| `/boosters` | unchanged | |
| `/boosters/join` | unchanged | |
| `/boosters/members` | unchanged | |
| `/boosters/sponsor` | inquiry form (option A) | updated submission flow |
| `/boosters/volunteer` | unchanged | drop `volunteer@`, use `boosters@` |
| `/boosters/committees` | unchanged | |
| `/boosters/board` | unchanged | |
| `/boosters/events` | unchanged | |
| `/boosters/documents` | unchanged | |
| `/boosters/donate` | unchanged | |
| `/about` | unchanged | |
| `/privacy` | unchanged | |
| `/404` | unchanged | |

Public route count went from 19 → roughly 11 base routes plus dynamic `[level]` and `[designation]` segments that expand to 7-9 actual schedule/roster pages depending on subdivisions.

---

## 9. Open questions remaining

1. **Stadium address for Kelly Reeves Athletic Complex** — still needs verification before launch (`site_pivot_addendum.md`). Not blocking the schema/content map work.
2. **Confirm rosters URL split** — I extrapolated split URLs to rosters based on the schedule pattern. Jeremy didn't explicitly say. Confirm or push back.
3. **Practice schedule team designation handling** — if Freshman is one team for games but split Blue/Green for practice (or vice versa), the URLs allow it. Confirm this is desired flexibility, not over-engineering.
4. **Footer icon layout** — merged row with tooltips (my pick) vs. two grouped rows (football + boosters separated). Confirm or override.

---

## What's next

If decisions above hold, schema is fully locked. Content map is locked. Moving to `admin_scope.md` — what each admin role can do across the new content types. Should be the easier doc since the data model and routes are now stable.

# Database Schema — Phase 1 Additions (Football Pivot)

Written 2026-05-16. **Reads with** `schema.md` (the original Phase 1 schema). This doc adds the four new tables required by the football-first pivot:

- `games` — schedule entries (varsity/jv/freshman per season)
- `rosters` — year-tagged roster pages (one per team level per year)
- `coaches` — coaching staff and trainers
- `resource_links` — links/forms for the Forms & Links page

Plus modifications to `site_settings`. No changes to existing tables.

All conventions from `schema.md` apply (uuid PKs, timestamptz audit, integer cents for money, soft delete via `active`, "2026-27" year format, RLS by default, etc.).

---

## New types

```sql
CREATE TYPE team_level AS ENUM ('varsity', 'jv', 'freshman');
CREATE TYPE home_or_away AS ENUM ('home', 'away', 'neutral');
CREATE TYPE game_result_status AS ENUM ('scheduled', 'final', 'cancelled', 'postponed', 'tbd');
CREATE TYPE coach_role_category AS ENUM ('head', 'coordinator', 'position_coach', 'trainer', 'staff');
CREATE TYPE resource_section AS ENUM ('registration_forms', 'communications', 'resources', 'stadiums', 'other');
```

`team_level` is reused across `games` and `rosters` so admin UIs can share the same dropdown.

---

## games

One row per game in the schedule. Each season has roughly 30-40 games across V/JV/Freshman (10-14 per team level). Phase 1 source-of-truth is the admin; MaxPreps is the **link** we surface to visitors for live scores. We don't sync from MaxPreps.

```sql
CREATE TABLE games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  team_level team_level NOT NULL,
  opponent text NOT NULL,                      -- "Round Rock"
  opponent_url text,                           -- optional, link to opponent's site
  game_date timestamptz NOT NULL,              -- kickoff time
  location text,                               -- "Kelly Reeves Athletic Complex"
  location_url text,                           -- optional, e.g., Google Maps link
  home_or_away home_or_away NOT NULL DEFAULT 'home',
  our_score integer CHECK (our_score IS NULL OR our_score >= 0),
  their_score integer CHECK (their_score IS NULL OR their_score >= 0),
  result_status game_result_status NOT NULL DEFAULT 'scheduled',
  watch_url text,                              -- YouTube, TexanLive, etc.
  maxpreps_game_url text,                      -- per-game deep link (optional)
  notes text,                                  -- "Homecoming", "Senior Night", etc.
  featured boolean NOT NULL DEFAULT false,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_games_year_team_date ON games(year, team_level, game_date);
CREATE INDEX idx_games_year_date ON games(year, game_date);
CREATE INDEX idx_games_status_date ON games(result_status, game_date);
CREATE INDEX idx_games_featured ON games(featured) WHERE featured = true;
```

**Design notes:**
- No `home_score`/`away_score` split. We always store as `our_score` and `their_score` because the booster club's audience is McNeil parents. Admin UI shows "McNeil X — Opponent Y" regardless of home/away.
- `result_status = 'scheduled'` for future games, `'final'` once scores are entered, `'tbd'` for placeholder rows (e.g., "playoff round 1 opponent TBD"), `'cancelled'` and `'postponed'` cover weather and scheduling changes.
- `featured` flag exists for things like "Game of the Week" treatment on the home page; not used in Phase 1 UI but the column lets us add the feature without a schema change later.
- `notes` is for game-specific context (Homecoming, Senior Night, Pink Out). Display on the schedule and game detail page.
- No unique constraint on `(year, team_level, game_date, opponent)` — we may legitimately have duplicates (rare, but e.g., scrimmage + regular game vs same opponent on different dates). Admin should de-dupe manually.

**"Next Game" query:**

```sql
SELECT * FROM games
WHERE team_level = 'varsity'
  AND result_status = 'scheduled'
  AND game_date > now()
ORDER BY game_date ASC
LIMIT 1;
```

If this returns nothing (offseason), home page falls back to `site_settings.next_game_override` text or hides the section.

---

## rosters

Year-tagged roster content. **One row per (year, team_level)** — three rows per season. Body is markdown, edited as a single document. We are explicitly NOT building a player records system; the coach won't maintain individual records, and we don't need to display per-player profiles.

```sql
CREATE TABLE rosters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  team_level team_level NOT NULL,
  body text NOT NULL DEFAULT '',               -- markdown
  source_note text,                            -- "Provided by Coach [Name] on YYYY-MM-DD"
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (year, team_level)
);

CREATE INDEX idx_rosters_year_active ON rosters(year, active);
```

**Design notes:**
- Unique constraint on `(year, team_level)` prevents duplicate rosters for the same team/year.
- `source_note` is admin-facing breadcrumb for "where did this roster come from" — useful when there's churn in head coaches.
- If we ever do want structured player records (Phase 3+), we add a `players` table that references `rosters.id` and render the structured version when populated, falling back to the markdown body otherwise. Doesn't require a breaking change.

---

## coaches

Coaching staff and trainers. Separate from `board_members` because audience and admin owner are different — booster officers own the board roster; the head coach (or AD) owns the coaches roster.

```sql
CREATE TABLE coaches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  name text NOT NULL,
  role text NOT NULL,                          -- "Defensive Coordinator"
  role_category coach_role_category NOT NULL,
  phone text,
  email text,
  photo_url text,
  bio text,                                    -- markdown
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_coaches_year_active_sort ON coaches(year, active, sort_order);
CREATE INDEX idx_coaches_year_category_sort ON coaches(year, role_category, sort_order);
```

**Design notes:**
- `role_category` exists so the public page can group coaches as Head Coach → Coordinators → Position Coaches → Trainers → Staff. Without it admins would re-sort manually every season.
- No unique constraint on `(year, role_category = 'head')`. The head coach slot can legitimately be empty (current McNeil situation) or, briefly, have multiple entries during a transition (e.g., "Interim Head Coach" listed alongside the previous head coach during a brief overlap). Validation lives in the admin UI: if more than one row has `role_category = 'head'` and `active = true`, show a warning.
- Phase 1 launches with NO head coach row at all per the Cruz decision (open decision #9 in `site_pivot_addendum.md`). Public page shows "Head Coach: position currently open" or hides the head coach card entirely when no active row with `role_category = 'head'` exists for the current year.

---

## resource_links

The Forms & Links page is a curated list of links/forms/PDFs. One table powers it.

```sql
CREATE TABLE resource_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section resource_section NOT NULL,
  label text NOT NULL,                         -- "Aktivate Registration"
  url text NOT NULL,                           -- external URL or internal path
  description text,                            -- one-line context shown below the link
  icon_hint text,                              -- "external", "pdf", "form", "video"
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_resource_links_section_active_sort
  ON resource_links(section, active, sort_order);
```

**Design notes:**
- `section` is an enum to keep the page predictable. If the board wants to add a section later, we add an enum value (one-line migration).
- `icon_hint` is a string rather than an enum so admins can use new values without schema changes; the frontend maps unknown values to a generic icon.
- No year tag. These are evergreen-ish; admins update in place when links change (e.g., RankOne → Aktivate).
- `stadiums` section uses the same table. Each stadium is one row: label = "Kelly Reeves Athletic Complex", url = Google Maps link, description = parking/address notes.

---

## site_settings — additions

The `site_settings` singleton needs new fields for the football-first home page and footer.

```sql
ALTER TABLE site_settings
  ADD COLUMN youtube_url text,
  ADD COLUMN instagram_url text,
  ADD COLUMN maxpreps_team_url text DEFAULT 'https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/',
  ADD COLUMN season_label text,                          -- "2026 Season"
  ADD COLUMN season_opener_date timestamptz,             -- for countdown when no scheduled games
  ADD COLUMN next_game_override text,                    -- admin override copy for the "next game" slot
  ADD COLUMN current_year text NOT NULL DEFAULT '2026-27';
```

**`current_year`** is the meaningful one. Every public route that filters by year (Roster, Coaches, Board, Sponsors, Membership tiers, Members list) reads from this. Admin sets it once per year. Avoids having "2026-27" hardcoded in 12 places.

**Update existing default:**

```sql
UPDATE site_settings
SET maxpreps_team_url = 'https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/'
WHERE id = 1 AND maxpreps_team_url IS NULL;
```

(Already handled by the column default, but listed for clarity if applying to an existing row.)

---

## Triggers

`touch_updated_at` applied to each new table:

```sql
CREATE TRIGGER touch_games BEFORE UPDATE ON games FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_rosters BEFORE UPDATE ON rosters FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_coaches BEFORE UPDATE ON coaches FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_resource_links BEFORE UPDATE ON resource_links FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

No custom validation triggers for the new tables. None have cross-record constraints comparable to `validate_membership_paid_state`.

---

## Row-Level Security

All four new tables follow the existing public-content pattern: anon reads visible rows; content_admin gets full CRUD.

```sql
-- games
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads games" ON games
  FOR SELECT TO anon
  USING (true);
CREATE POLICY "Authenticated read all games" ON games
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write games" ON games
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update games" ON games
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete games" ON games
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- rosters: anon reads only active rows; admins see archive too
ALTER TABLE rosters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active rosters" ON rosters
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all rosters" ON rosters
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write rosters" ON rosters
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update rosters" ON rosters
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete rosters" ON rosters
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- coaches: anon reads only active rows
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active coaches" ON coaches
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all coaches" ON coaches
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write coaches" ON coaches
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update coaches" ON coaches
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete coaches" ON coaches
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- resource_links: anon reads only active rows
ALTER TABLE resource_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active resource links" ON resource_links
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all resource links" ON resource_links
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write resource links" ON resource_links
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update resource links" ON resource_links
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete resource links" ON resource_links
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
```

**Why `games` is anon-readable even for unscheduled/cancelled rows:** historical scores are public information and visitors may bookmark old schedule URLs. We don't want to hide a game that was cancelled or marked TBD; show it with its status. Schema-level public read is safe; the schedule page UI is the only place that filters by status.

---

## Migration order

Apply to `db/migrations/` after the existing `010_seed.sql`:

```
011_football_pivot_types.sql       -- CREATE TYPE for the 5 new enums
012_football_pivot_tables.sql      -- games, rosters, coaches, resource_links
013_site_settings_additions.sql    -- ALTER TABLE site_settings ADD COLUMN ...
014_football_pivot_triggers.sql    -- touch_updated_at triggers
015_football_pivot_rls.sql         -- all the RLS policies
016_football_pivot_seed.sql        -- seed resource_links section structure
```

Apply in that order. Reset is the same as before — `DROP SCHEMA public CASCADE` then re-run all migrations 001-016.

---

## Seed data

### games — none

No seed. Admin enters games once per season from the coach's preseason schedule (or copies from MaxPreps once the district releases it). Total entry time per season: ~30 minutes for varsity, less for JV/freshman.

### rosters — empty stubs (optional)

To make the admin UI less surprising, seed three empty rows for the current year so admins see "Edit roster" buttons instead of "Create new":

```sql
INSERT INTO rosters (year, team_level, body, source_note) VALUES
  ('2026-27', 'varsity', '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'jv', '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'freshman', '', 'Awaiting roster from coaching staff');
```

Public-facing roster page shows "2026-27 roster coming soon" if `body` is empty. Admin UI shows the same row ready for editing.

### coaches — none

Per open decision #9, no head coach is listed at launch. Assistant coaches and trainers will be carried forward from the SE site capture (Tier 1 of `site_pivot_addendum.md`), but they need verification before they're inserted. No seed; populated post-capture during Step 7b admin work.

### resource_links — section scaffolding + known-good rows

Seed the section structure plus the rows we can confirm. The rest get added by Jeremy or board during/after the SE capture pass.

```sql
INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order) VALUES
  -- Registration & Forms
  ('registration_forms', 'Aktivate (Athletic Registration)', 'https://www.aktivate.com/', 'Required online registration for all athletes. Replaces the old RankOne system.', 'external', 1),
  ('registration_forms', 'UIL Forms', 'https://www.uiltexas.org/athletics/forms', 'University Interscholastic League required forms for participation.', 'external', 2),
  ('registration_forms', 'RRISD Athletic Forms', 'https://roundrockisd.org/athletics', 'Round Rock ISD athletic department forms and policies.', 'external', 3),
  -- Communications
  ('communications', 'HUDL', 'https://www.hudl.com/jointeam', 'Team video and stats platform. Team code provided by coaching staff.', 'external', 1),
  ('communications', 'SportsYou', '#', 'Team messaging app. Access code provided by coaching staff.', 'external', 2),
  -- Resources (empty until coach provides)
  -- Stadiums (empty until SE capture pass provides)
  ('stadiums', 'Kelly Reeves Athletic Complex', 'https://maps.google.com/?q=Kelly+Reeves+Athletic+Complex+Round+Rock+TX', 'McNeil home games. 10211 W Parmer Ln, Austin, TX 78717.', 'external', 1);
```

**Notes on the seed:**
- SportsYou URL is `#` (placeholder) because the access code on the existing SE site may be stale; we should not migrate it forward without verification.
- HUDL "team code provided by coaching staff" copy is intentionally generic so we don't have to update the description every season.
- Kelly Reeves address (10211 W Parmer Ln) is the public RRISD athletic complex address. Verify before launch.
- "Resources" section starts empty. Once the new head coach is in place and the SE capture is done, populate with the real workout schedules, summer conditioning, fall parent meeting docs, etc.

---

## What does NOT change from schema.md

To be explicit:

- All 13 existing tables (`user_roles`, `news_posts`, `events`, `membership_tiers`, `sponsorship_tiers`, `sponsors`, `board_members`, `committees`, `volunteer_opportunities`, `documents`, `payments`, `memberships`, `site_settings`) keep their existing structure. `site_settings` gets new columns added; no existing column is changed.
- All existing RLS policies stay as-is.
- All existing triggers stay as-is.
- The `public_members` view stays as-is.
- Storage buckets stay as-is. No new buckets needed; the new tables either use existing buckets (`board-photos` for `coaches.photo_url`, `documents` for any PDFs linked from `resource_links`) or use no storage (rosters body is text in DB, games store URLs to external services).

Wait — I want to call out the coaches/board photos question explicitly. **Decision:** add a new bucket `coach-photos`. Reusing `board-photos` is tempting but the audience and admin owners differ; better to keep them separate so we can introduce per-bucket policies later (e.g., if RRISD requires different consent handling for coach photos vs. parent-volunteer board photos). One-time setup cost; no ongoing burden.

```
coach-photos: public, max 5MB, image/png + image/jpeg + image/webp
```

Apply the same RLS pattern as the existing image buckets (anyone reads, content_admin uploads/updates/deletes).

---

## Open questions (don't block implementation)

1. **Should games tracking include "season type" (preseason/regular/playoffs/scrimmage)?** Right now everything is one bucket. Stony Point's site uses the `notes` field for this. Probably fine for Phase 1.
2. **Should rosters track jersey numbers or positions as structured fields?** Not in Phase 1. If we want a "search for player by name" feature later, that's when we revisit.
3. **Should there be a coaches.archived flag separate from active?** Currently `active = false` covers both "left the program" and "temporarily hidden." Fine for Phase 1.
4. **Game results — when admin updates a final score, should we auto-update result_status to 'final'?** Application logic, not schema. Yes, admin UI in Step 7b will do this.

---

## What's next

Schema patch ready. When CC's next pass picks up Step 4b / Step 5, this is the source-of-truth for the new tables.

Next CC doc rewrites in order:
1. `content_map.md` — every public route, what data it reads, what fields/sections each has
2. `admin_scope.md` — what each admin role can do across the new content types
3. `build_plan.md` — Step 4b inserted, Step 5 expanded, hard dates rechecked

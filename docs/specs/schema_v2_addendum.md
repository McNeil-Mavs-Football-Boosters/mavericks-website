# Schema v2 — Addendum (Jeremy revisions 2026-05-16)

Reads with `schema_v2.md`. These are revisions based on Jeremy's feedback:

- SportsYou access code: assume still valid, don't placeholder it
- Add Coach Wallin to seed (still on staff, no longer head coach)
- Coach photos bucket: confirmed
- Stadium address: verify before launch (no schema change, just an action)
- Structured player records: yes, with jersey number and position (both nullable)
- Archive old coaches: fine via existing `active` flag
- Auto-update game `result_status` to `'final'` when scores entered: yes (application logic)
- **Admin always has final say on schedule** — admin enters scrimmages and any unofficial games; we never auto-sync from MaxPreps. MaxPreps is read-only reference for visitors.

---

## 1. New table: players

The biggest revision. Structured player records replace the "single markdown blob per roster" approach. Each player gets a row; rosters table stays as the parent grouping. Markdown body on rosters becomes optional (for free-form notes like "Captains in **bold**" or preseason placeholder copy).

```sql
CREATE TABLE players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  roster_id uuid NOT NULL REFERENCES rosters(id) ON DELETE CASCADE,
  jersey_number text,                          -- text, not int (some teams use 00, letters)
  first_name text NOT NULL,
  last_name text NOT NULL,
  position text,                               -- "QB", "WR", "OL/DL", or null
  grade text,                                  -- "Sr.", "Jr.", "So.", "Fr.", or null
  height text,                                 -- "6'2"", or null
  weight integer CHECK (weight IS NULL OR weight > 0),
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_players_roster ON players(roster_id);
CREATE INDEX idx_players_roster_sort ON players(roster_id, sort_order);
CREATE INDEX idx_players_roster_active_sort ON players(roster_id, active, sort_order)
  WHERE active = true;

CREATE TRIGGER touch_players BEFORE UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

**Design notes:**

- `jersey_number` is **text**, not integer. High school football jerseys sometimes use `00`, letters, or duplicate numbers across position groups. Text avoids `0` vs `00` collapsing and lets us preserve whatever the coach sends.
- `first_name` and `last_name` are required; everything else is nullable. Per Jeremy's note: "obviously each player should have a number and position, but both could be unknowns too." We don't block roster import on missing data.
- `sort_order` is the admin's manual ordering. UI default when bulk-importing: rows get sequential sort_order in input order. Natural display sort is `sort_order ASC`, with `jersey_number` ascending as a fallback when sort_order ties (numeric where possible, lexicographic otherwise — application logic handles this).
- `position` is free-text rather than enum. Football position groups vary (e.g., "OLB" vs "Will/Sam", "OL" vs "OG/OT/OC"). Coach pastes what he uses; admin shows what's pasted. Standardizing constrains us without benefit.
- `grade` is free-text for the same reason. Common values: "Sr.", "Jr.", "So.", "Fr.". Admin can also use full words if coach prefers ("Senior").
- `height` is text to preserve formatting (`6'2"` reads cleaner than storing `74` inches and reformatting on display).
- `weight` is integer (pounds) because we may want sortable stats Phase 2+. If you want to store it as text for the same reasons as height, fine — flag and I'll revise. My pick: integer.
- `ON DELETE CASCADE` on the FK: if admin soft-archives a roster, players stay (just hidden via RLS). If admin **hard deletes** a roster (rare; usually for cleaning up test data), all players go with it. Cascade is correct here because orphan players have no display surface.

**Search:** Jeremy noted search isn't a priority. Skipping a search index in Phase 1. If we add player search later, a `GIN` index on `(first_name || ' ' || last_name)` with `pg_trgm` covers it without breaking changes.

---

## 2. Rosters table — minor revisions

Two changes to the rosters table from schema_v2:

1. `body` is now **optional preamble**, not the main content. Display order on the public roster page: optional `body` markdown (if present) → structured player table.
2. `source_note` semantics unchanged.

The schema_v2 SQL stands as written — `body text NOT NULL DEFAULT ''` already permits empty string. No SQL change needed. The semantic shift is in admin UI and public rendering, which is Step 7b / Step 5 territory.

**Updated public-page rendering logic** (for content_map.md to reference):

```
On /roster/{team_level}:
  - If no players AND no body → "2026-27 roster coming soon"
  - If body present → render markdown above the player table
  - If players present → render structured table (jersey #, name, position, grade, height, weight)
  - Both can be present; body is the preamble, players are the data
```

---

## 3. RLS for players

Same pattern as rosters — anon reads where parent roster is visible; content_admin full CRUD.

```sql
ALTER TABLE players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads players on active rosters" ON players
  FOR SELECT TO anon
  USING (
    active = true
    AND EXISTS (
      SELECT 1 FROM rosters
      WHERE rosters.id = players.roster_id
      AND rosters.active = true
    )
  );

CREATE POLICY "Authenticated read all players" ON players
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write players" ON players
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update players" ON players
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete players" ON players
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
```

**Subquery in the anon read policy** is the right pattern here. Postgres handles RLS subqueries fine at our scale (max ~150 player rows per season, looked up by roster_id which is indexed). The alternative — adding `year` and `team_level` columns to `players` and duplicating the filter — denormalizes for no real benefit.

**Privacy consideration:** when admin archives a roster (`active = false`), all its players become invisible to anon visitors. This matters because we're listing minor children by name. We want the off-switch.

---

## 4. Seed data revisions

### coaches — add Wallin

```sql
INSERT INTO coaches (year, name, role, role_category, sort_order, active) VALUES
  ('2026-27', 'Coach Wallin', 'Position Coach', 'position_coach', 10, true);
```

Per Jeremy: Wallin is still on the football staff, just no longer head coach. Bio, photo, exact role title, phone/email to be filled in by admin during the Step 7b CRUD pass (or from the SE site capture of `/dwallin`).

No head coach row is seeded. The public page's empty state covers this.

### resource_links — fix SportsYou seed

The original schema_v2 seed had `url = '#'` for SportsYou with a note that the access code might be stale. Per Jeremy, assume the SportsYou code is still good. Revised seed:

```sql
-- Replace this row from schema_v2 seed:
INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order) VALUES
  ('communications', 'SportsYou (Team Messaging)', 'https://www.sportsyou.com/', 'Team messaging app for parents and players. Use the access code from the SportsYou invite page in the SE capture, or contact the booster club at boosters@mcneilmavericks.org.', 'external', 2);
```

**Operational note:** the actual SportsYou access code lives in the existing SE site (per the third screenshot Jeremy sent). When Jeremy does the Tier 1 capture pass from `site_pivot_addendum.md`, the SportsYou page is one of the items. Admin then pastes the code into the `description` field at launch. Schema doesn't change.

---

## 5. Migration order — revised

Insert into `db/migrations/` in this order:

```
011_football_pivot_types.sql        -- 5 enums (unchanged from schema_v2)
012_football_pivot_tables.sql       -- games, rosters, coaches, resource_links
013_players_table.sql               -- NEW: players + index + trigger
014_site_settings_additions.sql     -- ALTER TABLE site_settings ADD COLUMN
015_football_pivot_triggers.sql     -- touch_updated_at on all new tables
016_football_pivot_rls.sql          -- RLS on games/rosters/coaches/resource_links
017_players_rls.sql                 -- NEW: RLS on players
018_football_pivot_seed.sql         -- revised seed including Wallin and SportsYou fix
```

(`013` and `017` are net-new files since the original schema_v2.)

---

## 6. Open questions — updates

Status of the four open questions in schema_v2.md:

1. **"season type" (preseason/regular/playoffs/scrimmage) field on games?** Still open, still fine for Phase 1 to use `notes` field. **Operational note from Jeremy:** admin enters scrimmages as regular game rows. We don't tag them differently in Phase 1. The `notes` field carries "Scrimmage" if relevant.

2. **Structured roster fields?** **Resolved: yes.** Players table added per Section 1 above.

3. **`coaches.archived` flag separate from `active`?** **Resolved: no.** `active = false` is sufficient. Jeremy confirmed.

4. **Auto-update `result_status` to `'final'` when score entered?** **Resolved: yes.** Application logic in the admin games CRUD route. Schema unchanged. The rule: when admin saves a games row with both `our_score IS NOT NULL` and `their_score IS NOT NULL` and the current status is `'scheduled'`, set status to `'final'` server-side before the write. Admin can still manually set any status (e.g., explicitly mark `'cancelled'` even with scores entered).

---

## 7. Operational principle for schedule data

Codifying Jeremy's point so it's not lost: **admin always has final say on the schedule.**

This is already implicit in the schema (no auto-sync, no MaxPreps import job, no scheduled task that writes to `games`), but worth stating explicitly so future iterations don't drift:

- We do not pull schedule data from MaxPreps, UIL, the district, or any external source. The `games` table is authoritative for what's displayed on the McNeil site.
- Admin enters scrimmages, jamborees, scout meetings, and any other on-field event as `games` rows. The `team_level` enum may need a future addition if youth or 7v7 events get added, but for Phase 1 V/JV/Freshman covers it.
- MaxPreps is presented to visitors as a separate, external service for live scores during a game. We don't claim it's our data.
- If MaxPreps and our schedule disagree (rare but possible — e.g., a last-minute reschedule MaxPreps hasn't caught), our schedule wins on our site. Admin can update.

This principle applies similarly to rosters (admin authoritative, never auto-synced) and coaches.

---

## 8. Coach photos bucket — confirmed

No change from schema_v2. Adding the bucket as originally specified:

```
coach-photos: public, max 5MB, image/png + image/jpeg + image/webp
```

Same RLS pattern as `board-photos`. Admins upload during the Step 7b coaches CRUD pass.

---

## What's next

Schema is locked. Moving to `content_map.md` — every public route, what it reads, sections per page. Will surface any further schema-impacting decisions there but I don't expect any.

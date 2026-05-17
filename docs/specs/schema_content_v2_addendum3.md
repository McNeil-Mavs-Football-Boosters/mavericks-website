# Schema + Content Map — Addendum 3

Written 2026-05-16. Reads with `schema_v2.md`, `schema_v2_addendum.md`, `content_map_v2.md`, `schema_content_v2_addendum2.md`. Three structural corrections based on Jeremy's feedback.

---

## 1. Freshman always has a designation in URL

**Rule:** when freshman exists, the URL is always `/schedule/games/freshman/green` (or `/blue`). There is no URL at `/schedule/games/freshman` — that returns 404.

Same applies to rosters: `/roster/freshman/green` (or `/blue`). No `/roster/freshman`.

Same applies to internal queries: any row in `games` or `rosters` with `team_level = 'freshman'` MUST have `team_designation` set (`'Green'` by default, `'Blue'` for the second team when enabled). No NULL designation for freshman.

**Designation convention:**
- Green is the canonical default. Single freshman team is always named Green.
- Blue is added when the squad splits. Optional, enabled by admin flag.
- Other designations (`'Gold'`, `'White'`, etc.) are not blocked at the schema level but aren't part of Phase 1 UI.

### URL routing rules

```
/schedule                            → 301 to /schedule/games/varsity
/schedule/games/varsity              → varsity games
/schedule/games/jv                   → JV games
/schedule/games/freshman             → 404 (no canonical URL)
/schedule/games/freshman/green       → freshman green's games (always exists when freshman exists)
/schedule/games/freshman/blue        → 404 when site_settings.freshman_has_blue=false; renders when true
/schedule/practice/varsity           → varsity practice
/schedule/practice/jv                → JV practice
/schedule/practice/freshman          → freshman practice (shared between green and blue)
/schedule/practice/freshman/*        → 404 (practice URL never has designation)
/roster                              → 301 to /roster/varsity
/roster/varsity
/roster/jv
/roster/freshman                     → 404
/roster/freshman/green               → freshman green's roster
/roster/freshman/blue                → 404 when flag=false; renders when true
```

### Nav rendering

In the header and on schedule/roster pages, the freshman tabs follow the flag:

When `freshman_has_blue = false`:
```
[ Varsity ] [ JV ] [ Freshman ]
```
The Freshman link points to `/schedule/games/freshman/green` (or `/roster/freshman/green`).

When `freshman_has_blue = true`:
```
[ Varsity ] [ JV ] [ Freshman Green ] [ Freshman Blue ]
```
Two separate tabs. No combined "Freshman" link.

### Storage convention

Schema doesn't change the unique-index expression from addendum 2 — `COALESCE(team_designation, '')` continues to work because varsity and JV legitimately have NULL designation. Only freshman is required-non-null, enforced in application code (not by a CHECK constraint, because adding one would force a backfill for any existing test data and isn't worth the surface area).

**For clarity in seed and queries:** freshman rows always have `team_designation` set to `'Green'` or `'Blue'`. The admin UI defaults the field when creating freshman rows.

---

## 2. Admin flag: site_settings.freshman_has_blue

```sql
ALTER TABLE site_settings
  ADD COLUMN freshman_has_blue boolean NOT NULL DEFAULT false;
```

Single boolean. System-wide, not year-scoped. When admin toggles it on:
- Nav shows Freshman Green / Freshman Blue tabs
- `/schedule/games/freshman/blue` and `/roster/freshman/blue` start rendering (assuming admin has created rows)
- Admin UI for games/rosters offers Blue as a designation option

When toggled off:
- Blue tabs disappear from nav
- `/schedule/games/freshman/blue` returns 404
- Existing Blue rows in the database become invisible to anon visitors

**Year-scoping note:** if McNeil ever has a year where freshman is split and the next year unified, the boolean toggles. Historical Blue data is hidden when the flag goes back to false (rows still exist in DB; just not exposed). If that hide-on-toggle behavior turns out to be wrong, future migration: convert `freshman_has_blue boolean` to a per-year config (`team_subdivisions` table). Not Phase 1.

**Why not a separate "team_subdivisions" table now:** YAGNI. McNeil currently has one freshman team. The flag handles the once-McNeil-actually-splits case. Generalizing to "any team level can be subdivided into N teams with custom names" is overengineering for a scenario that hasn't happened.

---

## 3. Practice schedules — revert team_designation column

Addendum 2 added `team_designation` to `practice_schedules`. Reverting. Practice is shared between Green and Blue by design — there's no scenario where they'd have separate practice schedules. Carrying a column that's always NULL is noise.

**Updated practice_schedules schema:**

```sql
CREATE TABLE practice_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,
  team_level team_level NOT NULL,
  body text NOT NULL DEFAULT '',
  source_note text,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (year, team_level)
);

CREATE INDEX idx_practice_schedules_year_active ON practice_schedules(year, active);
```

Plain `UNIQUE (year, team_level)` — no COALESCE needed because no designation.

Seed unchanged from addendum 2: three empty stubs for varsity / jv / freshman.

**Future migration path** (if practice ever needs to be split): `ALTER TABLE practice_schedules ADD COLUMN team_designation text;` plus rebuild unique index. One-line migration. Negligible cost to add later vs. carrying unused complexity now.

---

## 4. Multi-sport pushback acknowledged

Pulling back from the "architectural commitment" framing in addendum 2 Section 6.

**Updated position:** this is the football website. Period. No sport switcher in UI. No multi-sport navigation affordance on the home page. The URL paths happen to be sport-agnostic (`/schedule`, not `/football/schedule`) but that's not a feature; it's just not pre-branding for a future that may not happen.

If `/baseball` ever shows up, it's an additional standalone page reachable through... wherever Jeremy decides at that point. Not pre-designed. Not in Phase 1 scope, not in Phase 2 scope, not in any current scope.

The previous "future migration path" SQL in addendum 2 Section 6 is **deleted from the spec**. If it ever needs to happen, we design it then with the actual constraints in hand.

---

## 5. Updated migration order

Migrations 019 and 020 from addendum 2 are revised:

```
019_team_designation.sql              (ALTER games, rosters; same as before)
020_practice_schedules.sql            (NO team_designation column — revised)
021_practice_schedules_rls.sql        (unchanged)
022_sponsorship_inquiries.sql         (unchanged)
023_site_settings_socials.sql         (unchanged from addendum 2)
023b_site_settings_freshman_blue.sql  (NEW — ALTER site_settings ADD freshman_has_blue)
024_practice_schedules_seed.sql       (unchanged — three stubs)
```

Numbering not critical, just for build_plan tracking.

---

## 6. Seed data revisions

### rosters — seed with Green for freshman

Updating the seed from `schema_v2_addendum.md`:

```sql
INSERT INTO rosters (year, team_level, team_designation, body, source_note) VALUES
  ('2026-27', 'varsity',  NULL,     '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'jv',       NULL,     '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'freshman', 'Green',  '', 'Awaiting roster from coaching staff');
```

No Blue row in seed — admin creates one after toggling `freshman_has_blue = true`.

### Site settings already covered — flag defaults to false

The `freshman_has_blue` column defaults to false. No explicit seed line needed.

---

## 7. Final updated route map

Replacing the table from addendum 2 Section 8:

| URL | Purpose | Notes |
|---|---|---|
| `/` | Home | unchanged |
| `/schedule` | 301 → `/schedule/games/varsity` | |
| `/schedule/games/varsity` | Varsity games | |
| `/schedule/games/jv` | JV games | |
| `/schedule/games/freshman/green` | Freshman Green games | always present |
| `/schedule/games/freshman/blue` | Freshman Blue games | exists only when `freshman_has_blue = true` |
| `/schedule/practice/varsity` | Varsity practice | |
| `/schedule/practice/jv` | JV practice | |
| `/schedule/practice/freshman` | Freshman practice | shared, no designation in URL |
| `/roster` | 301 → `/roster/varsity` | |
| `/roster/varsity` | | |
| `/roster/jv` | | |
| `/roster/freshman/green` | Freshman Green roster | always present |
| `/roster/freshman/blue` | Freshman Blue roster | only when flag true |
| `/coaches` | unchanged | |
| `/news`, `/news/[slug]` | unchanged | |
| `/sponsors` | unchanged | |
| `/resources` | unchanged | |
| `/boosters` and sub-pages | unchanged | |
| `/about`, `/privacy`, `/404` | unchanged | |

Phase 1 route count: ~16 distinct routes when `freshman_has_blue = false`; ~18 when true.

---

## What's next

Schema and content map locked. Three docs:
- `schema.md` (original — unchanged tables)
- `schema_v2.md` + `schema_v2_addendum.md` + `schema_content_v2_addendum2.md` + this doc (additions)
- `content_map_v2.md` + `schema_content_v2_addendum2.md` + this doc (routes)

These are messy to read across, but each one was a focused decision pass. Once `admin_scope.md` is done, I'll consider whether a clean consolidated rewrite is worth doing (one canonical schema doc, one canonical content_map doc) or whether the trail of addenda is fine.

Moving to `admin_scope.md` next.

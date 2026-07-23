-- 078_preseason_scrimmages_2026.sql
--
-- Adds the two 2026 preseason opponent scrimmages to the games schedule (these
-- were the "Aug 13 / Aug 20 preseason TBD" slots migration 057 omitted for lack
-- of an opponent). Both are HOME; notes = 'Scrimmage'. Per the coaches' calendar:
--   * Thu Aug 13 vs Hendrickson — firm times: Varsity 7:00 PM, JV + Freshmen
--     5:30 PM. result_status = 'scheduled'.
--   * Thu Aug 20 vs Eastview — time TBD in the source, so result_status = 'tbd'
--     (the games views now render "TBD" in the time cell for tbd games). The
--     stored game_date time is a nominal placeholder; the date (Aug 20) is real.
-- Freshmen rows are mirrored Green + Blue at the single advertised time, matching
-- the migration 032 convention. Venue (KRAC vs McNeil Stadium) is unknown for a
-- scrimmage, so location is left NULL.
--
-- August 2026 is CDT (-05). Game 1 vs Bowie (Aug 28) is already seeded (057) —
-- not touched here. Idempotent: INSERT-if-absent per (year, team_level,
-- team_designation, opponent, game_date).

BEGIN;

-- Thu Aug 13 vs Hendrickson (HOME) — firm times ------------------------------
INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'varsity', NULL, 'Hendrickson High School', '2026-08-13 19:00:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='varsity' AND team_designation IS NULL AND opponent='Hendrickson High School' AND game_date='2026-08-13 19:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'jv', NULL, 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='jv' AND team_designation IS NULL AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Green', 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Green' AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Blue', 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Blue' AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

-- Thu Aug 20 vs Eastview (HOME) — time TBD -----------------------------------
INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'varsity', NULL, 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='varsity' AND team_designation IS NULL AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'jv', NULL, 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='jv' AND team_designation IS NULL AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Green', 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Green' AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Blue', 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Blue' AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

COMMIT;

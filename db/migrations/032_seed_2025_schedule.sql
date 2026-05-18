-- Migration 032: TEST DATA. Replace the 9 throwaway placeholder games
-- (seeded by 027/028, then relabeled to 2025-26 by 030) with the real
-- 2025 McNeil schedule from docs/2025 Football schedule.pdf.
--
-- 46 rows total: V=11, JV=11, Freshman Blue=12, Freshman Green=12.
-- BYE weeks (Oct 17 V / Oct 16 JV+F) are skipped because the schema
-- requires opponent NOT NULL. Cedar Park (Aug 16, freshman) carries
-- notes='Scrimmage' per the schema_v2_addendum operational note.
--
-- Decisions:
-- - result_status='scheduled' for all games. The 2025 season is over
--   but the PDF carries no scores; honest representation is "we have
--   the schedule, not the results." Admin CRUD will backfill.
-- - opponent_url and location_url NULL on every row. Admin populates.
-- - Freshman Blue plays 5:00 PM, Freshman Green plays 6:30 PM on the
--   ten split-time games (per the schedule footer). Aug 16 Cedar Park
--   scrimmage and Aug 21 Anderson are duplicated across both teams at
--   the single advertised time so both /freshman/blue and
--   /freshman/green pages render them.
-- - Times use America/Chicago. CDT through Nov 2, 2025; CST from
--   Nov 3 onward. Nov 6 (JV+F Hutto) and Nov 7 (V Hutto) fall in CST.
-- - Notes: 'Homecoming' (V Sep 12 Westwood), 'Senior Night' (V Oct 31
--   Manor), 'Scrimmage' (F Aug 16 Cedar Park). District (*) markers
--   from the PDF are ignored — no column for it.
--
-- Cleanup before public cutover:
--   DELETE FROM games WHERE year='2025-26';

BEGIN;

-- 1. Clear the 9 throwaway placeholder games from migrations 027+028.
DELETE FROM games WHERE year = '2025-26';

-- 2. Insert the real 2025 V/JV schedule.
INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url, game_date, location, location_url,
  home_or_away, result_status, our_score, their_score,
  watch_url, notes, featured
) VALUES
  -- VARSITY (11)
  ('2025-26', 'varsity', NULL, 'Anderson',                 NULL, '2025-08-21 19:30 America/Chicago', 'House Park',       NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Weiss High School',        NULL, '2025-08-28 19:00 America/Chicago', 'The Pfield',       NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Lake Belton High School',  NULL, '2025-09-04 19:00 America/Chicago', 'Gupton Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Westwood High School',     NULL, '2025-09-12 19:00 America/Chicago', 'KRAC',             NULL, 'home',    'scheduled', NULL, NULL, NULL, 'Homecoming',   false),
  ('2025-26', 'varsity', NULL, 'Round Rock High School',   NULL, '2025-09-19 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Stony Point High School',  NULL, '2025-09-26 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Vandegrift High School',   NULL, '2025-10-03 19:00 America/Chicago', 'Monroe Stadium',   NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Vista Ridge High School',  NULL, '2025-10-10 19:00 America/Chicago', 'KRAC',             NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Cedar Ridge High School',  NULL, '2025-10-24 19:00 America/Chicago', 'KRAC',             NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Manor High School',        NULL, '2025-10-31 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, 'Senior Night', false),
  ('2025-26', 'varsity', NULL, 'Hutto High School',        NULL, '2025-11-07 19:00 America/Chicago', 'Memorial Stadium', NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),

  -- JV (11)
  ('2025-26', 'jv', NULL, 'Anderson',                 NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Weiss High School',        NULL, '2025-08-27 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Lake Belton High School',  NULL, '2025-09-03 17:00 America/Chicago', 'Lake Belton HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Westwood High School',     NULL, '2025-09-11 18:00 America/Chicago', 'Westwood HS',       NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Round Rock High School',   NULL, '2025-09-18 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Stony Point High School',  NULL, '2025-09-25 17:00 America/Chicago', 'Stony Point HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Vandegrift High School',   NULL, '2025-10-02 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Vista Ridge High School',  NULL, '2025-10-09 18:00 America/Chicago', 'Vista Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Cedar Ridge High School',  NULL, '2025-10-23 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Manor High School',        NULL, '2025-10-30 18:00 America/Chicago', 'Manor HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Hutto High School',        NULL, '2025-11-06 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),

  -- FRESHMAN BLUE (12) — Aug 16 + Aug 21 combined-time; the rest at 5:00 PM
  ('2025-26', 'freshman', 'Blue',  'Cedar Park High School',    NULL, '2025-08-16 10:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Scrimmage', false),
  ('2025-26', 'freshman', 'Blue',  'Anderson',                  NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Weiss High School',         NULL, '2025-08-27 17:00 America/Chicago', 'Weiss HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Lake Belton High School',   NULL, '2025-09-03 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Westwood High School',      NULL, '2025-09-11 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Round Rock High School',    NULL, '2025-09-18 17:00 America/Chicago', 'Round Rock HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Stony Point High School',   NULL, '2025-09-25 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Vandegrift High School',    NULL, '2025-10-02 17:00 America/Chicago', 'Vandegrift HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Vista Ridge High School',   NULL, '2025-10-09 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Cedar Ridge High School',   NULL, '2025-10-23 17:00 America/Chicago', 'Cedar Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Manor High School',         NULL, '2025-10-30 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Hutto High School',         NULL, '2025-11-06 17:00 America/Chicago', 'Hutto HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),

  -- FRESHMAN GREEN (12) — same opponents/sites as Blue; split-time games at 6:30 PM
  ('2025-26', 'freshman', 'Green', 'Cedar Park High School',    NULL, '2025-08-16 10:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Scrimmage', false),
  ('2025-26', 'freshman', 'Green', 'Anderson',                  NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Weiss High School',         NULL, '2025-08-27 18:30 America/Chicago', 'Weiss HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Lake Belton High School',   NULL, '2025-09-03 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Westwood High School',      NULL, '2025-09-11 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Round Rock High School',    NULL, '2025-09-18 18:30 America/Chicago', 'Round Rock HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Stony Point High School',   NULL, '2025-09-25 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Vandegrift High School',    NULL, '2025-10-02 18:30 America/Chicago', 'Vandegrift HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Vista Ridge High School',   NULL, '2025-10-09 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Cedar Ridge High School',   NULL, '2025-10-23 18:30 America/Chicago', 'Cedar Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Manor High School',         NULL, '2025-10-30 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Hutto High School',         NULL, '2025-11-06 18:30 America/Chicago', 'Hutto HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false);

COMMIT;

-- Migration 027: test seed for `games` table (slice 4 of Commit B).
--
-- Purpose
--   Slice 4 needs rendered rows on every /schedule/games/* page so the table
--   render and home-tint / result-cell / Watch-icon logic can be exercised
--   on Vercel preview. There is no admin CRUD yet (lands in Step 7b or 13),
--   so we seed plausible Central Texas opponents and result states.
--
-- Coverage
--   varsity:        5 rows (final win, final loss, scheduled, cancelled, tbd)
--   jv:             2 rows (final win, scheduled)
--   freshman/Green: 2 rows (scheduled home, scheduled away)
--   Total: 9 rows, all year='2026-27'.
--
-- Cleanup
--   When real games are entered via admin CRUD (Step 7b or 13), drop the
--   whole test set in one shot:
--       DELETE FROM games WHERE year = '2026-27';
--   This whole row set is intended to be replaced, not merged with, real data.

BEGIN;

-- Varsity (team_designation NULL)
INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url,
  game_date,
  location, location_url,
  home_or_away,
  our_score, their_score, result_status,
  watch_url, notes
) VALUES
  -- 1. Final, win, home, watch_url, Homecoming
  (
    '2026-27', 'varsity', NULL,
    'Hutto', NULL,
    '2026-09-25 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', NULL,
    'home',
    35, 14, 'final',
    'https://www.youtube.com/watch?v=test-mcneil-hutto', 'Homecoming'
  ),
  -- 2. Final, loss, away, no notes
  (
    '2026-27', 'varsity', NULL,
    'Cedar Ridge', NULL,
    '2026-09-04 19:30:00 America/Chicago'::timestamptz,
    'Cedar Ridge High School', NULL,
    'away',
    21, 28, 'final',
    NULL, NULL
  ),
  -- 3. Scheduled, home, opponent_url + location_url
  (
    '2026-27', 'varsity', NULL,
    'Round Rock', 'https://roundrockfootball.example.com/',
    '2026-10-09 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex',
    'https://maps.google.com/?q=Kelly+Reeves+Athletic+Complex+Round+Rock+TX',
    'home',
    NULL, NULL, 'scheduled',
    NULL, NULL
  ),
  -- 4. Cancelled, away
  (
    '2026-27', 'varsity', NULL,
    'Vista Ridge', NULL,
    '2026-10-16 19:30:00 America/Chicago'::timestamptz,
    'Vista Ridge High School', NULL,
    'away',
    NULL, NULL, 'cancelled',
    NULL, NULL
  ),
  -- 5. TBD, home
  (
    '2026-27', 'varsity', NULL,
    'Westwood', NULL,
    '2026-10-30 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', NULL,
    'home',
    NULL, NULL, 'tbd',
    NULL, NULL
  );

-- JV (team_designation NULL)
INSERT INTO games (
  year, team_level, team_designation,
  opponent, game_date,
  location, home_or_away,
  our_score, their_score, result_status
) VALUES
  -- 1. Final, win, home
  (
    '2026-27', 'jv', NULL,
    'Hutto',
    '2026-09-17 18:00:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', 'home',
    24, 7, 'final'
  ),
  -- 2. Scheduled, away
  (
    '2026-27', 'jv', NULL,
    'Stony Point',
    '2026-10-01 18:00:00 America/Chicago'::timestamptz,
    'Stony Point High School', 'away',
    NULL, NULL, 'scheduled'
  );

-- Freshman Green
INSERT INTO games (
  year, team_level, team_designation,
  opponent, game_date,
  location, home_or_away,
  result_status
) VALUES
  -- 1. Scheduled, home
  (
    '2026-27', 'freshman', 'Green',
    'Cedar Ridge',
    '2026-09-17 16:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', 'home',
    'scheduled'
  ),
  -- 2. Scheduled, away
  (
    '2026-27', 'freshman', 'Green',
    'Round Rock',
    '2026-10-01 16:30:00 America/Chicago'::timestamptz,
    'Round Rock High School', 'away',
    'scheduled'
  );

COMMIT;

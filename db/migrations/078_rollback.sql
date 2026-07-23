-- 078_rollback.sql
-- Reverses 078 by deleting the two preseason scrimmages (all team rows) by
-- (year, opponent, game_date).

BEGIN;

DELETE FROM games
WHERE year = '2026-27'
  AND opponent IN ('Hendrickson High School', 'Eastview High School')
  AND game_date IN (
    '2026-08-13 19:00:00-05'::timestamptz,
    '2026-08-13 17:30:00-05'::timestamptz,
    '2026-08-20 18:00:00-05'::timestamptz
  );

COMMIT;

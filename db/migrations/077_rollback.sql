-- 077_rollback.sql
-- Reverses 077 by deleting the 2026-27 practice_schedules rows it seeded.
-- (The empty 2025-26 rows are untouched.)

BEGIN;

DELETE FROM practice_schedules
WHERE year = '2026-27'
  AND team_level IN ('varsity', 'jv', 'freshman');

COMMIT;

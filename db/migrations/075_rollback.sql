-- 075_rollback.sql
-- Reverses 075_coaches_2026_offensive_staff.sql by deleting the 5 seeded coaches by (year, name).

BEGIN;

DELETE FROM coaches
WHERE year = '2026-27'
  AND name IN (
    'Alexander Gillis',
    'Barrett Matthews',
    'Thomas Umberger',
    'Ryan Doyle',
    'Devonte Jones'
  );

COMMIT;

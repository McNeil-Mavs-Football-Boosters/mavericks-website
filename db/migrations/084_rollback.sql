-- 084_rollback.sql
-- Reverses 084 by deleting the meal-program row by (section, label).

BEGIN;

DELETE FROM resource_links
WHERE section = 'registration_forms'
  AND label = 'Game-Day Meal Program (Parent Payment)';

COMMIT;

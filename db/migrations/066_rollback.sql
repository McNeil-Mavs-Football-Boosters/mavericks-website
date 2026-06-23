-- 066_rollback.sql
-- Reverses 066_coach_justin_ward.sql.

BEGIN;

-- Remove Justin Ward.
DELETE FROM coaches
WHERE year = '2026-27' AND name = 'Justin Ward';

COMMIT;

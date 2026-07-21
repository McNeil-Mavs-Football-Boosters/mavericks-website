-- 076_rollback.sql
-- Reverses 076: Justin Ward back to Receiver Coach.

BEGIN;

UPDATE coaches
SET role = 'Receiver Coach'
WHERE year = '2026-27'
  AND name = 'Justin Ward'
  AND role = 'Running Backs Coach';

COMMIT;

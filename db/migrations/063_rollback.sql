-- 063_rollback.sql
-- Reverses 063: "Ashley Root" -> "Ashley Olson" on the 2026-27 board.

BEGIN;

UPDATE board_members
SET name = 'Ashley Olson'
WHERE year = '2026-27'
  AND name = 'Ashley Root';

COMMIT;

-- 063_fix_ashley_surname.sql
--
-- Correct the Treasurer's surname on the 2026-27 board: "Ashley Olson" -> "Ashley Root".
-- Migration 061 carried the old seed surname "Olson" (from migration 010); the board
-- confirmed 2026-06-15 her name is Ashley Root. Name only; role/email unchanged.
-- The /boosters board section revalidates every 60s, so this propagates live without a redeploy.
--
-- Idempotent: re-run is a no-op once the row already reads "Ashley Root".

BEGIN;

UPDATE board_members
SET name = 'Ashley Root'
WHERE year = '2026-27'
  AND name = 'Ashley Olson';

COMMIT;

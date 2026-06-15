-- 061_rollback.sql
-- Reverses 061_board_card_update.sql, restoring the 2026-27 board to its
-- pre-061 state (the original 010 seed values).

BEGIN;

-- 4. Clear the placeholder contact email off the filled members.
UPDATE board_members
SET email_alias = NULL
WHERE year = '2026-27'
  AND email_alias = 'mcneilfootballboosters@gmail.com';

-- 2. Ashley Olson: Treasurer -> Co-Treasurer.
UPDATE board_members
SET role = 'Co-Treasurer'
WHERE year = '2026-27'
  AND name = 'Ashley Olson'
  AND role = 'Treasurer';

-- 1. Reactivate Chevon Williams.
UPDATE board_members
SET active = true
WHERE year = '2026-27'
  AND name = 'Chevon Williams'
  AND role = 'Treasurer'
  AND active = false;

-- 3 + column: drop the vacancy flag entirely. This also clears Sylvia's vacancy
-- state (her email_alias was already NULL in the seed, so nothing to restore there).
ALTER TABLE board_members DROP COLUMN IF EXISTS is_vacant;

COMMIT;

-- 061_board_card_update.sql
--
-- 2026-27 board roster + display changes (spec: docs/specs/board_card_update_spec.md).
--
-- Schema decisions (made against the live schema, not guessed):
--   * Email column already exists: board_members.email_alias (nullable text).
--   * Soft-delete flag already exists: board_members.active (boolean). Chevon is
--     deactivated, not hard-deleted.
--   * Vacancy needs an explicit representation. board_members.name is NOT NULL, so
--     it can't be nulled, and matching a sentinel name string in the UI would be a
--     fragile heuristic. This migration adds an explicit is_vacant boolean instead;
--     the card render keys off the flag.
--
-- Roster changes:
--   1. Chevon Williams (Treasurer)  -> soft-deleted (active = false).
--   2. Ashley Olson "Co-Treasurer"  -> "Treasurer".
--   3. Sylvia Brito (VP of Merchandise) -> vacancy (is_vacant = true, email cleared;
--      role text unchanged per spec).
--   4. Every remaining FILLED 2026-27 member gets the placeholder contact email
--      mcneilfootballboosters@gmail.com. This is the shared booster inbox, used as a
--      placeholder until per-role .org aliases land in J9; see 053 for the same
--      placeholder pattern on site_settings. Reversed by 061_rollback.sql.
--
-- Idempotent: each UPDATE is guarded so a re-run is a no-op.

BEGIN;

-- Explicit vacancy flag (no-op if a prior run already added it).
ALTER TABLE board_members ADD COLUMN IF NOT EXISTS is_vacant boolean NOT NULL DEFAULT false;

-- 1. Soft-delete Chevon Williams.
UPDATE board_members
SET active = false
WHERE year = '2026-27'
  AND name = 'Chevon Williams'
  AND role = 'Treasurer'
  AND active = true;

-- 2. Ashley Olson: Co-Treasurer -> Treasurer.
UPDATE board_members
SET role = 'Treasurer'
WHERE year = '2026-27'
  AND name = 'Ashley Olson'
  AND role = 'Co-Treasurer';

-- 3. Sylvia Brito -> vacancy (role text stays "VP of Merchandise"; no email).
UPDATE board_members
SET is_vacant = true,
    email_alias = NULL
WHERE year = '2026-27'
  AND name = 'Sylvia Brito'
  AND is_vacant = false;

-- 4. Placeholder contact email on every remaining FILLED 2026-27 member.
--    Runs last so the deactivated (Chevon) and vacant (Sylvia) rows are excluded.
UPDATE board_members
SET email_alias = 'mcneilfootballboosters@gmail.com'
WHERE year = '2026-27'
  AND active = true
  AND is_vacant = false;

COMMIT;

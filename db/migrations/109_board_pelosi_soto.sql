-- 109_board_pelosi_soto.sql
--
-- 2026-27 board: add Rocco Pelosi as a second Treasurer alongside Ashley Root,
-- and fill the VP of Merchandise vacancy with Monica Soto.
--
-- Per Jeremy (2026-08-02): both are already members of their role Google Groups,
-- so email_alias points at the role address, not the shared booster Gmail.
--   * Rocco Pelosi  -> treasurer@mcneilmavericks.org   (same address as Ashley)
--   * Monica Soto   -> merchandise@mcneilmavericks.org (one of the 14 aliases)
--
-- Two decisions worth recording:
--
-- 1. Rocco is INSERTED at sort_order 4 and everything from 4 down shifts by one,
--    rather than being appended at the end. The ask was that the two Treasurer
--    cards sit next to each other; Ashley is at 3 and sort_order is an integer,
--    so there is no value between 3 and 4 to slot into. There is no unique
--    constraint on sort_order, so the shift is a single statement.
--    Chevon Williams (inactive, sort_order 2) is deliberately left where she is
--    -- she is filtered out by active=false and moving her would be noise.
--
-- 2. Sylvia Brito's vacancy row is SOFT-DELETED and Monica is a NEW row, rather
--    than renaming Sylvia's row to Monica. That row carries Sylvia's history and
--    her created_at; renaming a person's record to a different person loses one
--    and falsifies the other. active=false matches how Chevon was retired in
--    migration 061. The "Position Open" card disappears as a side effect, which
--    is the intent -- the seat is filled.
--
-- Idempotent: guarded inserts, and the sort_order shift is skipped if Rocco is
-- already present.

BEGIN;

-- 1. Make room at sort_order 4, but only on a first run.
UPDATE board_members
SET sort_order = sort_order + 1
WHERE year = '2026-27'
  AND sort_order >= 4
  AND NOT EXISTS (
    SELECT 1 FROM board_members
    WHERE year = '2026-27' AND name = 'Rocco Pelosi'
  );

-- 2. Rocco Pelosi, Treasurer, immediately after Ashley Root.
INSERT INTO board_members (name, role, email_alias, sort_order, year, active, is_vacant)
SELECT 'Rocco Pelosi', 'Treasurer', 'treasurer@mcneilmavericks.org', 4, '2026-27', true, false
WHERE NOT EXISTS (
  SELECT 1 FROM board_members WHERE year = '2026-27' AND name = 'Rocco Pelosi'
);

-- 3. Retire the VP of Merchandise vacancy placeholder.
UPDATE board_members
SET active = false
WHERE year = '2026-27'
  AND name = 'Sylvia Brito'
  AND is_vacant = true
  AND active = true;

-- 4. Monica Soto fills VP of Merchandise. Sorts where the vacancy card sat.
INSERT INTO board_members (name, role, email_alias, sort_order, year, active, is_vacant)
SELECT 'Monica Soto', 'VP of Merchandise', 'merchandise@mcneilmavericks.org', 7, '2026-27', true, false
WHERE NOT EXISTS (
  SELECT 1 FROM board_members WHERE year = '2026-27' AND name = 'Monica Soto'
);

COMMIT;

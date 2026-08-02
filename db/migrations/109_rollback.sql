-- 109_rollback.sql
-- Reverses 109: removes Rocco Pelosi and Monica Soto, restores the VP of
-- Merchandise vacancy card, and un-shifts sort_order.
--
-- Order matters: delete Rocco BEFORE the un-shift, so the shift-back is not
-- blocked by his row and does not drag him along.

BEGIN;

DELETE FROM board_members WHERE year = '2026-27' AND name = 'Rocco Pelosi';
DELETE FROM board_members WHERE year = '2026-27' AND name = 'Monica Soto';

UPDATE board_members
SET sort_order = sort_order - 1
WHERE year = '2026-27'
  AND sort_order >= 5;

UPDATE board_members
SET active = true
WHERE year = '2026-27'
  AND name = 'Sylvia Brito'
  AND is_vacant = true;

COMMIT;

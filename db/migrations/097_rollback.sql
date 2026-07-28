-- 097_rollback.sql
-- Reverses 097_resources_add_one_mav_parent_meeting_deck.sql by deleting the
-- row by label. Does NOT delete the PDF from the `documents` bucket — remove
-- documents/meetings/one-mav-parent-athlete-meeting-2026-07-27.pdf by hand if
-- the file itself should come down.

BEGIN;

DELETE FROM resource_links
WHERE section = 'resources'
  AND label = 'ONE MAV Parent & Athlete Meeting (July 27, 2026)';

COMMIT;

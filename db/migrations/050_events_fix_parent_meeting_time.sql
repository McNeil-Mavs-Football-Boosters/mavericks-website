-- 050_events_fix_parent_meeting_time.sql
--
-- Migration 048 seeded the Parent and Athlete Meeting at 7:00 PM CDT
-- (19:00). Actual start time is 6:30 PM CDT. End time stays at 8:30 PM
-- CDT (the meeting now runs 2 hours instead of the original 1.5).

BEGIN;

UPDATE events
SET starts_at = '2026-05-26 18:30:00-05'::timestamptz
WHERE slug = 'parent-athlete-meeting-may-2026';

COMMIT;

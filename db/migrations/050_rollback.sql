-- 050_rollback.sql
-- Reverses 050_events_fix_parent_meeting_time.sql by restoring the
-- 7:00 PM start time from migration 048.

BEGIN;

UPDATE events
SET starts_at = '2026-05-26 19:00:00-05'::timestamptz
WHERE slug = 'parent-athlete-meeting-may-2026';

COMMIT;

-- 079_rollback.sql
-- Reverses 079, restoring the 6:00 PM placeholder + "(Time TBA)" title from 071.

BEGIN;

UPDATE events SET
  starts_at = '2026-07-27 18:00:00-05'::timestamptz,
  ends_at = NULL,
  title = 'Parent & Athlete Meeting (Time TBA)',
  description = 'Meeting for parents and athletes ahead of the 2026 season. The start time is TBA and will be posted here as soon as it is announced. Check back for updates.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND title = 'Parent & Athlete Meeting';

COMMIT;

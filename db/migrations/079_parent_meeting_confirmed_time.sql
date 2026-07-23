-- 079_parent_meeting_confirmed_time.sql
--
-- The Parent & Athlete Meeting time is confirmed by the coaches' calendar:
-- Mon July 27 2026, 6:30-8:00 PM. Replaces the 6:00 PM placeholder + "(Time TBA)"
-- title seeded by migration 071. July 27 is CDT (-05).
--
-- Idempotent: guarded on the placeholder title.

BEGIN;

UPDATE events SET
  starts_at = '2026-07-27 18:30:00-05'::timestamptz,
  ends_at = '2026-07-27 20:00:00-05'::timestamptz,
  title = 'Parent & Athlete Meeting',
  description = 'Meeting for parents and athletes ahead of the 2026 season at McNeil High School.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND title = 'Parent & Athlete Meeting (Time TBA)';

COMMIT;

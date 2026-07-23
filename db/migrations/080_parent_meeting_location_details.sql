-- 080_parent_meeting_location_details.sql
--
-- Adds the location + fuller description to the Parent & Athlete Meeting from
-- Coach Gardner's Facebook event: the meeting is in the McNeil HS Cafeteria,
-- and the agenda covers the practice schedule, program expectations, and
-- staffing. Date/time (Mon Jul 27, 6:30 PM) already set by migration 079.
--
-- Idempotent: guarded on the slug + the 079 description (so it only patches the
-- row still holding the location-less description).

BEGIN;

UPDATE events SET
  location = 'McNeil High School Cafeteria',
  location_url = 'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  description = 'Coach Gardner invites all football players and parents to kick off the 2026-27 season. The meeting is at 6:30 PM in the cafeteria at McNeil High School. The agenda includes the practice schedule, program expectations, and staffing.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND description = 'Meeting for parents and athletes ahead of the 2026 season at McNeil High School.';

COMMIT;

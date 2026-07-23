-- 080_rollback.sql
-- Reverses 080, restoring the location-less description from 079.

BEGIN;

UPDATE events SET
  location = NULL,
  location_url = NULL,
  description = 'Meeting for parents and athletes ahead of the 2026 season at McNeil High School.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND location = 'McNeil High School Cafeteria';

COMMIT;

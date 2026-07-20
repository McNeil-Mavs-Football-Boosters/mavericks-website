-- 072_rollback.sql
-- Reverses 072_photo_shoot_confirmed_time.sql, restoring the provisional
-- 8:00-9:00 AM window and TBD description from migration 070.

BEGIN;

UPDATE events SET
  starts_at = '2026-07-26 08:00:00-05'::timestamptz,
  ends_at = '2026-07-26 09:00:00-05'::timestamptz,
  description = 'Photo shoot for senior football players and cheerleaders at McNeil High School. Exact start time is TBD until the photographer confirms lighting, but it will be in the morning between 8:00 and 9:00 AM. We will update this page as soon as the time is confirmed.'
WHERE slug = 'senior-photo-shoot-2026';

COMMIT;

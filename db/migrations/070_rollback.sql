-- 070_rollback.sql
-- Reverses 070_events_seed_senior_photo_shoot_2026.sql by deleting the seeded event by slug.

BEGIN;

DELETE FROM events
WHERE slug = 'senior-photo-shoot-2026';

COMMIT;

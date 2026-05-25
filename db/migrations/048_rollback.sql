-- 048_events_seed_rollback.sql
-- Reverses 048_events_seed.sql by deleting the three seeded events by slug.

BEGIN;

DELETE FROM events
WHERE slug IN (
  'parent-athlete-meeting-may-2026',
  'football-banquet-2025',
  'meet-the-mavs-2025'
);

COMMIT;

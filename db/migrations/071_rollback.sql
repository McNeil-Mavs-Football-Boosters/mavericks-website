-- 071_rollback.sql
-- Reverses 071_events_seed_july_2026_slate.sql by deleting the 5 seeded events by slug.

BEGIN;

DELETE FROM events
WHERE slug IN (
  'rice-mcneil-stronger-together',
  'youth-football-camp-2026',
  'parent-athlete-meeting-2026',
  'senior-equipment-pickup-2026',
  'jr-soph-equipment-pickup-2026'
);

COMMIT;

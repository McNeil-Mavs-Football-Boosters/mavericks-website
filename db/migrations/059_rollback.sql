-- 059_rollback.sql
-- Reverses 059_events_seed_pool_party_2026.sql by deleting the seeded event by slug.

BEGIN;

DELETE FROM events
WHERE slug = 'pool-party-2026';

COMMIT;

-- 065_rollback.sql
-- Reverses 065_pool_party_relocate_morningside.sql by restoring the 059 venue.

BEGIN;

UPDATE events
SET
  location = 'Pearson Place Pavilion (Avery Ranch)',
  location_url = 'https://maps.google.com/?q=10000+Ivalenes+Hope+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

-- 065_pool_party_relocate_morningside.sql
--
-- Relocates the 2026 McNeil Mavs Pool Party (seeded in 059) to Morningside Pool
-- in Avery Ranch. Date/time unchanged (Fri Aug 7 2026, 5:00-8:00 PM CDT).
--
-- New venue: Morningside Pool (Avery Ranch)
--   14100 Morgan Creek Dr, Austin, TX 78717

BEGIN;

UPDATE events
SET
  location = 'Morningside Pool (Avery Ranch)',
  location_url = 'https://maps.google.com/?q=14100+Morgan+Creek+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

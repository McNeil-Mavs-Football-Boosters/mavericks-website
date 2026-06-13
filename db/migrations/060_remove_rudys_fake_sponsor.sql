-- 060_remove_rudys_fake_sponsor.sql
--
-- Removes the "Rudy's BBQ" sponsor seeded by migration 041. It was a
-- placeholder/test row (never a real sponsor) sitting at the MVP tier.
-- Deleting it clears the MVP slot until a real top-tier sponsor is added.
--
-- The 3 sponsor_spotlight hero tiles from 041 (one referenced Rudy's)
-- were already deleted by migration 043, so only the sponsors row remains.

BEGIN;

DELETE FROM sponsors
WHERE name = 'Rudy''s BBQ'
  AND year = '2025-26';

COMMIT;

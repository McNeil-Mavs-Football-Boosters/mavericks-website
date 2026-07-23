-- 081_rollback.sql
-- Reverses 081: clears the signup link and restores the prior (14100) map address.

BEGIN;

UPDATE events SET
  signup_url = NULL,
  location_url = 'https://maps.google.com/?q=14100+Morgan+Creek+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

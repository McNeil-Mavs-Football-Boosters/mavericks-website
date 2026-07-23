-- 081_pool_party_signup_and_address.sql
--
-- Pool Party (Fri Aug 7 2026) updates from the official booster flyer:
--   * Add the SignUpGenius link (donated-food signup) as signup_url — the event
--     detail page renders it as a "Sign Up →" button.
--   * Fix the map address: the flyer says 10121 Morgan Creek Dr, Austin TX 78717;
--     the stored location_url pointed at 14100 Morgan Creek Dr (wrong street #).
-- Date/time/location name unchanged (Fri Aug 7, 5:00-8:00 PM, Morningside Pool).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-64853046-2026?useFullSite=true#/',
  location_url = 'https://maps.google.com/?q=10121+Morgan+Creek+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

-- 059_events_seed_pool_party_2026.sql
--
-- Seeds the 2026 Mavs Football Pool Party as a published upcoming event
-- on /events (events_page_spec.md). Same column set and CDT offset
-- convention as 048_events_seed.sql.
--
-- Aug 7, 2026 falls inside Central Daylight Time, so the offset is -05.
-- Location is Pearson Place Pavilion at the Avery Ranch community pool
-- (10000 Ivalenes Hope Dr, Austin, TX 78717), per the 2025 flyer.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'McNeil Mavs Pool Party',
  'pool-party-2026',
  'Join us for the 2026 Mavs Football Pool Party. All teams and parents are welcome, and the Mavs coaching staff and members of the booster club will be there. The booster club provides the mains; parents are asked to donate drinks, desserts, fruit/veggies, sides, and chips. Please make sure to pick your athlete up by 8:00 PM.',
  '2026-08-07 17:00:00-05'::timestamptz,
  '2026-08-07 20:00:00-05'::timestamptz,
  'Pearson Place Pavilion (Avery Ranch)',
  'https://maps.google.com/?q=10000+Ivalenes+Hope+Dr+Austin+TX+78717',
  'published',
  false
);

COMMIT;

-- 087_events_seed_community_night_2026.sql
--
-- Seeds the Phil's & Amy's Community Night (profit-share fundraiser) as a
-- published event on /events. Confirmed official (Carol, 2026-07-24).
-- Tue Aug 4, 2026, 4:00-8:00 PM CDT (-05) at Phil's Ice House on US-183.
-- Same pattern as 059_events_seed_pool_party_2026.sql.
--
-- Idempotent: INSERT-if-absent on slug.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
)
SELECT
  'Phil’s & Amy’s Community Night',
  'community-night-phils-amys-2026',
  'Join the Mavs for a Community Night at Phil’s Ice House (183) on Tuesday, August 4, 4:00–8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team — everyone in your party counts, so bring the whole family. An easy, delicious way to fuel the season.',
  '2026-08-04 16:00:00-05'::timestamptz,
  '2026-08-04 20:00:00-05'::timestamptz,
  'Phil’s Ice House (183)',
  'https://maps.google.com/?q=13265+N+US-183+Austin+TX+78750',
  'published',
  false
WHERE NOT EXISTS (
  SELECT 1 FROM events WHERE slug = 'community-night-phils-amys-2026'
);

COMMIT;

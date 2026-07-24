-- 090_events_seed_senior_program_ad.sql
--
-- Seeds "Reserve a Senior Program Ad" as a published event with a July 31
-- deadline, so it shows in Upcoming until then and auto-drops to Past on Aug 1.
-- Sign-up button = the senior-ad Google Form ($25 / quarter page). No physical
-- location. July is CDT (-05). Same seed pattern as 059.
--
-- Idempotent: INSERT-if-absent on slug.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at, location, location_url, signup_url, status, featured
)
SELECT
  'Reserve a Senior Program Ad',
  'senior-program-ad-2026',
  'Feature your senior in the Spirit Book, the football program produced by the cheer boosters. Senior ads are $25 per quarter page. Reserve your spot by July 31 using the sign-up button.',
  '2026-07-31 23:59:00-05'::timestamptz,
  NULL,
  NULL,
  NULL,
  'https://docs.google.com/forms/d/e/1FAIpQLScGDI6gHk6-hyVJDBxrZAwiNpQwLDeHzjQ74Npg57nwvKjCSQ/viewform',
  'published',
  false
WHERE NOT EXISTS (
  SELECT 1 FROM events WHERE slug = 'senior-program-ad-2026'
);

COMMIT;

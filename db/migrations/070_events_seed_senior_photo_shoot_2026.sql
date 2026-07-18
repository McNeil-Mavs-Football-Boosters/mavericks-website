-- 070_events_seed_senior_photo_shoot_2026.sql
--
-- Seeds the 2026 Senior Photo Shoot (senior football players + cheerleaders)
-- as a published upcoming event on /events. Same column set and CDT offset
-- convention as 059_events_seed_pool_party_2026.sql.
--
-- Jul 26, 2026 falls inside Central Daylight Time, so the offset is -05.
-- Exact start time is TBD pending the photographer's lighting check; the
-- 8:00-9:00 AM window is the confirmed morning range and the description
-- carries the TBD note. Update starts_at/ends_at once the time is set.
-- Location is McNeil High School (5720 McNeil Drive, Austin, TX 78729).

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Senior Photo Shoot (Football & Cheer)',
  'senior-photo-shoot-2026',
  'Photo shoot for senior football players and cheerleaders at McNeil High School. Exact start time is TBD until the photographer confirms lighting, but it will be in the morning between 8:00 and 9:00 AM. We will update this page as soon as the time is confirmed.',
  '2026-07-26 08:00:00-05'::timestamptz,
  '2026-07-26 09:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

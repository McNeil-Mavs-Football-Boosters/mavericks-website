-- 071_events_seed_july_2026_slate.sql
--
-- Seeds 5 late-July 2026 events as published rows on /events, following the
-- seed pattern of 048_events_seed.sql / 059_events_seed_pool_party_2026.sql.
-- All dates fall inside Central Daylight Time, so the offset is -05.
-- Weekdays verified against the 2026 calendar: Jul 22 Wed, Jul 24 Fri,
-- Jul 27 Mon, Jul 29 Wed, Jul 30 Thu.
--
-- Notes:
--   * Parent & Athlete Meeting: real start time not yet announced. starts_at
--     is NOT NULL and the UI always renders a time, so 6:00 PM is seeded as a
--     placeholder with "(Time TBA)" in the title (Jeremy 2026-07-17). Patch
--     starts_at/ends_at + strip the title suffix + TBA sentence once Coach
--     posts the time.
--   * Equipment pickups: description embeds a Markdown link to the RankOne
--     forms portal (URL from migration 035). Renders as a link on the event
--     detail page (ReactMarkdown); shows as raw markdown in the list view's
--     clamped preview and the ICS feed, so it sits last in the description.
--   * Meet the Mavs and scrimmages intentionally excluded (dates contested;
--     separate migration later). Pool party already seeded by 059/065.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Stronger Together: McNeil Football x Rice Football',
  'rice-mcneil-stronger-together',
  'A joint character and leadership session with Rice University Football, with Rice players joining virtually. Open to sophomores, juniors, and seniors only. Pizza will be served at 11:30 AM, and the program begins at 1:00 PM. Sponsored by the McNeil Football Booster Club.',
  '2026-07-22 13:00:00-05'::timestamptz,
  NULL,
  'Team Room G204, McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '7th-9th Grade Football Camp',
  'youth-football-camp-2026',
  'Football camp for 7th, 8th, and 9th graders hosted by McNeil Football. Please arrive by 7:50 AM.',
  '2026-07-24 08:00:00-05'::timestamptz,
  '2026-07-24 11:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Parent & Athlete Meeting (Time TBA)',
  'parent-athlete-meeting-2026',
  'Meeting for parents and athletes ahead of the 2026 season. The start time is TBA and will be posted here as soon as it is announced. Check back for updates.',
  '2026-07-27 18:00:00-05'::timestamptz,
  NULL,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Equipment Pickup - Seniors',
  'senior-equipment-pickup-2026',
  'Equipment pickup for seniors only. All RankOne athletic forms must be complete ("all green") before any equipment can be issued. Forms are available through [RRISD Athletic Forms](https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx).',
  '2026-07-29 10:00:00-05'::timestamptz,
  '2026-07-29 11:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Equipment Pickup - Juniors & Sophomores',
  'jr-soph-equipment-pickup-2026',
  'Equipment pickup for juniors and sophomores. All RankOne athletic forms must be complete ("all green") before any equipment can be issued. Forms are available through [RRISD Athletic Forms](https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx).',
  '2026-07-30 10:00:00-05'::timestamptz,
  '2026-07-30 13:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

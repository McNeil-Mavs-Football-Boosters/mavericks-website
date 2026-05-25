-- 048_events_seed.sql
--
-- Seeds 3 initial events for the new /events page (events_page_spec.md).
-- One upcoming (Parent and Athlete Meeting on 2026-05-26) and two past
-- (2025 Football Banquet, 2025 Meet the Mavs) so the Upcoming/Past
-- filter pills demo with real data.
--
-- Time-zone offsets are explicit: -05 for Central Daylight (CDT), -06
-- for Central Standard (CST). The August 2025 and May 2026 dates fall
-- inside CDT; the December 2025 banquet falls inside CST.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Parent and Athlete Meeting',
  'parent-athlete-meeting-may-2026',
  'Important meeting for parents and athletes covering the 2026-27 season. Topics include summer workouts, fall expectations, and key dates for the upcoming season. Please make every effort to attend.',
  '2026-05-26 19:00:00-05'::timestamptz,
  '2026-05-26 20:30:00-05'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Football Banquet',
  'football-banquet-2025',
  'End-of-season celebration honoring the 2025 McNeil Mavericks varsity, JV, and freshman football teams. Awards, video highlights, and dinner.',
  '2025-12-06 18:00:00-06'::timestamptz,
  '2025-12-06 21:00:00-06'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Meet the Mavs',
  'meet-the-mavs-2025',
  'Annual season-kickoff event introducing the 2025-26 Mavericks football team to the community. Player introductions, coach remarks, and food.',
  '2025-08-15 18:00:00-05'::timestamptz,
  '2025-08-15 20:00:00-05'::timestamptz,
  'McNeil High School Stadium',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

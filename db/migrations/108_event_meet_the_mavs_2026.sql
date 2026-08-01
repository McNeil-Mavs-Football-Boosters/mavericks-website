-- 108_event_meet_the_mavs_2026.sql
--
-- Meet the Mavs 2026, Friday August 14. Closes the open item that has been
-- carried since 2026-07-17 ("date contested Aug 14 vs 15"); Jeremy confirmed
-- Aug 14 on 2026-08-01.
--
-- Checked before seeding: Aug 14 2026 is a Friday and nothing else is on it.
-- The Hendrickson scrimmage is the night before (Aug 13, V 7:00 / JV+F 5:30),
-- which is what booster_club_info flagged as the thing that might move this
-- event -- it does not conflict.
--
-- ⚠️ TIME AND LOCATION ARE INHERITED FROM THE 2025 EVENT (6:00-8:00 PM at
-- McNeil High School Stadium, migration 048), NOT independently confirmed for
-- 2026. Only the date came from Jeremy. events.starts_at is NOT NULL so a time
-- had to be chosen; last year's is the best available answer. Correct it if the
-- committee sets a different window.
--
-- August 2026 is CDT, hence -05.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, location_url, status)
values (
  '2026 Meet the Mavs',
  'meet-the-mavs-2026',
  'Annual season-kickoff event introducing the 2026-27 Mavericks football team to the community. Player introductions, coach remarks, and food.',
  '2026-08-14 18:00:00-05',
  '2026-08-14 20:00:00-05',
  'McNeil High School Stadium',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published'
)
on conflict (slug) do nothing;

commit;

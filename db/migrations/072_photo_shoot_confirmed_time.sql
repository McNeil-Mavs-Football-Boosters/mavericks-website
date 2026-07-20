-- 072_photo_shoot_confirmed_time.sql
--
-- The Senior Photo Shoot time is confirmed (Amanda, cheer boosters,
-- 2026-07-20): Sunday July 26 at 10:30 AM, meet at the McNeil entrance in
-- jerseys and jeans. Replaces the provisional 8:00-9:00 AM window and the
-- TBD note seeded by migration 070. Adds the Spirit Book context and the
-- senior-ad order form link ($25 per quarter page); the form URL renders
-- as a link on the event detail page (ReactMarkdown, same pattern as the
-- RankOne link in 071).
--
-- No end time was announced, so ends_at goes to NULL (the UI renders a
-- bare start time in that case).

BEGIN;

UPDATE events SET
  starts_at = '2026-07-26 10:30:00-05'::timestamptz,
  ends_at = NULL,
  description = 'Senior football players and cheerleaders are featured on the cover of the Spirit Book, the program produced by the cheer boosters. Seniors should meet at the entrance of McNeil High School at 10:30 AM wearing jerseys and jeans. Senior ads in the program are available for $25 per quarter page: [reserve a senior ad here](https://docs.google.com/forms/d/e/1FAIpQLScGDI6gHk6-hyVJDBxrZAwiNpQwLDeHzjQ74Npg57nwvKjCSQ/viewform).'
WHERE slug = 'senior-photo-shoot-2026';

COMMIT;

-- 096_rename_senior_program_ad_to_shoutout.sql
--
-- Renames the senior Spirit Book item from "Senior Program Ad(s)" to
-- "Senior Shoutout(s)" so parents don't read it as a paid business ad
-- (board ask, 2026-07-28). Touches display copy only:
--   * hero_foreground_tiles headline "Senior Program Ads" -> "Senior Shoutouts"
--   * events.title "Reserve a Senior Program Ad" -> "Reserve a Senior Shoutout"
--   * events.description "Senior ads are $25..." -> "Senior shoutouts are $25..."
--
-- The slug stays 'senior-program-ad-2026' on purpose: it is the hero tile's
-- cta_url and may already be shared in Facebook posts / the newsletter.
-- The *sponsorship* "Program Ad" add-on (mig 086) is a real business ad and is
-- deliberately NOT renamed.
--
-- Idempotent: matched on the tile cta_url / event slug, re-runnable.

BEGIN;

UPDATE hero_foreground_tiles
SET payload = jsonb_set(payload, '{headline}', '"Senior Shoutouts"'::jsonb)
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/senior-program-ad-2026';

UPDATE events
SET title = 'Reserve a Senior Shoutout',
    description = 'Feature your senior in the Spirit Book, the football program produced by the cheer boosters. Senior shoutouts are $25 per quarter page. Reserve your spot by July 31 using the sign-up button.'
WHERE slug = 'senior-program-ad-2026';

COMMIT;

-- 096_rollback.sql
-- Reverses 096: restores the "Senior Program Ad(s)" wording.

BEGIN;

UPDATE hero_foreground_tiles
SET payload = jsonb_set(payload, '{headline}', '"Senior Program Ads"'::jsonb)
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/senior-program-ad-2026';

UPDATE events
SET title = 'Reserve a Senior Program Ad',
    description = 'Feature your senior in the Spirit Book, the football program produced by the cheer boosters. Senior ads are $25 per quarter page. Reserve your spot by July 31 using the sign-up button.'
WHERE slug = 'senior-program-ad-2026';

COMMIT;

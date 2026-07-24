-- 091_hero_tiles_expiry.sql
--
-- Adds date-based auto-expiry to homepage carousel tiles + uses it:
--   * new column expires_at (nullable); the carousel loader hides tiles past it.
--   * Community Night tile → expires Aug 5 (event is Aug 4).
--   * new Senior Program Ads tile → links to the senior-ad event, expires Aug 1.
-- July/Aug are CDT (-05). Idempotent: column IF NOT EXISTS; guarded UPDATE/INSERT.

BEGIN;

ALTER TABLE hero_foreground_tiles ADD COLUMN IF NOT EXISTS expires_at timestamptz;

UPDATE hero_foreground_tiles
SET expires_at = '2026-08-05 00:00:00-05'::timestamptz
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/community-night-phils-amys-2026';

INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order, active, expires_at)
SELECT 'headline_cta',
  '{"headline":"Senior Program Ads","subhead":"Feature your senior in the football program. $25 per quarter page. Reserve by July 31.","cta_label":"Reserve Now","cta_url":"/events/senior-program-ad-2026"}'::jsonb,
  6, true, '2026-08-01 00:00:00-05'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM hero_foreground_tiles
  WHERE tile_type = 'headline_cta'
    AND payload->>'cta_url' = '/events/senior-program-ad-2026'
);

COMMIT;

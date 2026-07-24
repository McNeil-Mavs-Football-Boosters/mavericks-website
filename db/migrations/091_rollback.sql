-- 091_rollback.sql
BEGIN;
DELETE FROM hero_foreground_tiles
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/senior-program-ad-2026';
UPDATE hero_foreground_tiles
SET expires_at = NULL
WHERE payload->>'cta_url' = '/events/community-night-phils-amys-2026';
ALTER TABLE hero_foreground_tiles DROP COLUMN IF EXISTS expires_at;
COMMIT;

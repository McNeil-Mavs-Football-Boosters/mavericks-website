-- 089_rollback.sql
-- Reverses 089 by deleting the Community Night carousel tile.

BEGIN;

DELETE FROM hero_foreground_tiles
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/community-night-phils-amys-2026';

COMMIT;

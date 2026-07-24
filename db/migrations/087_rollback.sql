-- 087_rollback.sql
-- Reverses 087 by deleting the Community Night event by slug.

BEGIN;

DELETE FROM events WHERE slug = 'community-night-phils-amys-2026';

COMMIT;

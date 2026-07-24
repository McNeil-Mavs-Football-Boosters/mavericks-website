-- 088_photo_shoot_jeans_only.sql
--
-- Senior photo shoot (7/26): coaches hand out jerseys AT the shoot (players
-- don't take them home), so "wearing jerseys and jeans" is wrong. Change to
-- jeans only + note jerseys are provided. Time (10:30 AM) unchanged.
--
-- Idempotent: targeted REPLACE, guarded on the old phrase.

BEGIN;

UPDATE events
SET description = replace(
      description,
      'wearing jerseys and jeans.',
      'wearing jeans. Jerseys will be handed out at the shoot.'
    )
WHERE slug = 'senior-photo-shoot-2026'
  AND description LIKE '%wearing jerseys and jeans.%';

COMMIT;

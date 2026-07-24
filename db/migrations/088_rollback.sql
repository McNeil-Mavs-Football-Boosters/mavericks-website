-- 088_rollback.sql
-- Reverses 088: restore "wearing jerseys and jeans."

BEGIN;

UPDATE events
SET description = replace(
      description,
      'wearing jeans. Jerseys will be handed out at the shoot.',
      'wearing jerseys and jeans.'
    )
WHERE slug = 'senior-photo-shoot-2026'
  AND description LIKE '%Jerseys will be handed out at the shoot.%';

COMMIT;

-- 082_rollback.sql
-- Reverses 082: clears the camp registration signup link.

BEGIN;

UPDATE events SET
  signup_url = NULL
WHERE slug = 'youth-football-camp-2026';

COMMIT;

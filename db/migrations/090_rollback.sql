-- 090_rollback.sql
BEGIN;
DELETE FROM events WHERE slug = 'senior-program-ad-2026';
COMMIT;

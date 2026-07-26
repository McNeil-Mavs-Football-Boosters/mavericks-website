-- 094_rollback.sql
-- Reverses 094: removes the Rudy's BBQ MVP sponsor row again.

BEGIN;

DELETE FROM sponsors WHERE name = 'Rudy''s BBQ' AND year = '2025-26';

COMMIT;

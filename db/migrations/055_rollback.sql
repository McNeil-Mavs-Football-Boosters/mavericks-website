-- Rollback for migration 055.
-- Removes Gardner, moves the existing coaches back to 2025-26, and drops the
-- current_coaches_year column. Run only if reverting the coaches year split.

BEGIN;

DELETE FROM coaches WHERE year = '2026-27' AND name = 'Jerry Gardner' AND role_category = 'head';

UPDATE coaches SET year = '2025-26' WHERE year = '2026-27';

ALTER TABLE site_settings DROP COLUMN IF EXISTS current_coaches_year;

COMMIT;

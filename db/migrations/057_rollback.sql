-- Rollback 057
BEGIN;
DELETE FROM games WHERE year='2026-27';
DELETE FROM rosters WHERE year='2026-27' AND pdf_storage_path IS NULL;
COMMIT;

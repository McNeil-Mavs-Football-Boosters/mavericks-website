-- Rollback 056
BEGIN;
ALTER TABLE site_settings DROP COLUMN IF EXISTS current_schedule_year;
COMMIT;

-- Rollback 058
BEGIN;
UPDATE site_settings SET current_schedule_year = '2025-26' WHERE id = 1;
COMMIT;

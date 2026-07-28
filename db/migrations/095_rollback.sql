-- Rollback 095
-- Drops the column; the roster pages fall back to current_year ('2025-26'),
-- which restores the 2025-26 rosters on the public pages.
BEGIN;
ALTER TABLE site_settings DROP COLUMN IF EXISTS current_roster_year;
COMMIT;

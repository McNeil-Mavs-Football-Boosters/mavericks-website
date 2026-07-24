-- 086_rollback.sql
-- Reverses 086: removes the Program Ad add-on and drops price_display.
-- (Pair with reverting the sponsor-page code that selects price_display.)

BEGIN;

DELETE FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Program Ad';
ALTER TABLE sponsorship_tiers DROP COLUMN IF EXISTS price_display;

COMMIT;

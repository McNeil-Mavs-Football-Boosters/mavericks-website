-- Migration 056: decouple the displayed SCHEDULE year from current_year.
-- Same pattern as current_board_year (030) and current_coaches_year (055).
-- Default '2025-26' so NOTHING changes on deploy; migration 058 flips it to
-- '2026-27' as the single go-live switch. Rosters/practice/sponsors/tiers stay
-- on current_year='2025-26' and are unaffected.
BEGIN;
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_schedule_year text NOT NULL DEFAULT '2025-26';
UPDATE site_settings SET current_schedule_year = '2025-26' WHERE id = 1;
COMMIT;

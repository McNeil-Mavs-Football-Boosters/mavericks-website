-- Migration 030: Split site_settings year fields and relabel football
-- seed rows from "2026-27" to "2025-26".
--
-- Schema add: site_settings.current_board_year (governs board data).
-- site_settings.current_year now governs only football data (rosters,
-- practice_schedules, coaches, games). Board year is decoupled because
-- the operating board year and the football season being displayed are
-- on different cadences.
--
-- Data relabel: rosters, practice_schedules, coaches, games move from
-- "2026-27" -> "2025-26" to match the actual data we have (the season
-- just completed). board_members stays at "2026-27" — current board is
-- already the 2026-27 board. membership_tiers, sponsorship_tiers, and
-- every other year-stamped table are untouched.
--
-- Idempotent: each UPDATE filters by the current value, so re-running
-- against a database that has already moved forward is a no-op.
-- Reversible: an inverse migration can flip values back; the new
-- column can be dropped if needed (no data depends on it before this
-- migration ships).

BEGIN;

ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_board_year text NOT NULL DEFAULT '2026-27';

UPDATE site_settings      SET current_year = '2025-26' WHERE current_year = '2026-27';
UPDATE rosters            SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE practice_schedules SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE coaches            SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE games              SET year         = '2025-26' WHERE year         = '2026-27';

COMMIT;

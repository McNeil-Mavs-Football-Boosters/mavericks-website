-- Migration 058: GO-LIVE. Flip the public schedule to the 2026-27 season.
-- Pre-req: 056 applied, 057 seeded, code reads current_schedule_year, and the
-- corrected PDF uploaded to documents bucket at schedules/2026-27.pdf.
-- Reversible: 058_rollback.sql sets it back to 2025-26.
BEGIN;
UPDATE site_settings SET current_schedule_year = '2026-27' WHERE id = 1;
COMMIT;

-- Migration 025: Backfill site_settings.mailing_address into a migration so a
-- fresh DB rebuild reproduces the live two-line render. Idempotent: re-runs
-- as a no-op once the value is set. Completes the 4b live-seed carryover.

UPDATE site_settings
SET mailing_address = E'#412, 6001 W Parmer Ln, Suite 370\nAustin, TX 78727'
WHERE id = 1
  AND (mailing_address IS NULL OR mailing_address = '');

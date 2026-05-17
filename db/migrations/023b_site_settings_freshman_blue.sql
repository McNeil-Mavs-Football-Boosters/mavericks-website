-- Migration 023b: site_settings.freshman_has_blue toggle.
-- Per schema_content_v2_addendum3.md section 2. Admin flips this to enable
-- the freshman Blue team alongside the default Green.

ALTER TABLE site_settings
  ADD COLUMN freshman_has_blue boolean NOT NULL DEFAULT false;

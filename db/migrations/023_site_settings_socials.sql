-- Migration 023: Rename facebook_group_url -> facebook_boosters_url and add
-- football/X social fields. Addendum 2 narrative says rename (preserves the
-- seeded value); the SQL block in that section that ADDs facebook_boosters_url
-- is a copy-paste error.

BEGIN;

ALTER TABLE site_settings RENAME COLUMN facebook_group_url TO facebook_boosters_url;
ALTER TABLE site_settings ADD COLUMN facebook_football_url text;
ALTER TABLE site_settings ADD COLUMN x_football_url text;
ALTER TABLE site_settings ADD COLUMN x_boosters_url text;

COMMIT;

-- 064_restore_org_email_addresses.sql
--
-- Cloudflare Email Routing for mcneilmavericks.org is now live (2026-06-15), so
-- the temporary Gmail placeholders come off the public site and the real .org
-- addresses go in. This supersedes migration 053 (the temp boosters@->gmail swap)
-- and replaces the shared-Gmail board placeholder seeded by migration 061.
--
--   * site_settings.primary_contact_email: gmail -> boosters@mcneilmavericks.org
--   * SportsYou resource_links description: gmail -> boosters@mcneilmavericks.org
--   * board_members.email_alias: shared Gmail placeholder -> per-role .org address
--
-- Idempotent: each UPDATE is guarded on the old Gmail value.

BEGIN;

-- General contact (drives Footer + /boosters).
UPDATE site_settings
SET primary_contact_email = 'boosters@mcneilmavericks.org'
WHERE id = 1
  AND primary_contact_email = 'mcneilfootballboosters@gmail.com';

-- SportsYou resource description embeds the contact email in body text.
UPDATE resource_links
SET description = REPLACE(description, 'mcneilfootballboosters@gmail.com', 'boosters@mcneilmavericks.org')
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%mcneilfootballboosters@gmail.com%';

-- Board cards: map the shared Gmail placeholder to each role's .org address.
UPDATE board_members SET email_alias = 'president@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Carol Glinski' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'treasurer@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Ashley Root' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'secretary@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Jeremy Vest' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'vicepresident@mcneilmavericks.org'
  WHERE year = '2026-27' AND name IN ('Kendra Jalbert', 'Shannon Schoepflin') AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'membership@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Debby Mata' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'boosters@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Monica Woods' AND email_alias = 'mcneilfootballboosters@gmail.com';

COMMIT;

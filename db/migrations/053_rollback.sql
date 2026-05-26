-- 053_rollback.sql
--
-- Reverses 053_temporary_swap_contact_email_to_gmail.sql once Cloudflare Email
-- Routing is live and boosters@mcneilmavericks.org actually forwards somewhere.

BEGIN;

UPDATE site_settings
SET primary_contact_email = 'boosters@mcneilmavericks.org'
WHERE id = 1
  AND primary_contact_email = 'mcneilfootballboosters@gmail.com';

UPDATE resource_links
SET description = REPLACE(
  description,
  'mcneilfootballboosters@gmail.com',
  'boosters@mcneilmavericks.org'
)
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%mcneilfootballboosters@gmail.com%';

COMMIT;

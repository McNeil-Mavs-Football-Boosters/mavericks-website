-- 053_temporary_swap_contact_email_to_gmail.sql
--
-- TEMPORARY swap of boosters@mcneilmavericks.org → mcneilfootballboosters@gmail.com
-- on every public-surface DB row, so the board's pre-admin-phase review (2026-05-26
-- meeting) doesn't see an aliased address that isn't wired up yet. The .org alias
-- will be restored via 053_rollback.sql once Cloudflare Email Routing is live.
--
-- Affected rows:
--   1. site_settings.primary_contact_email (singleton row, id=1)
--   2. resource_links SportsYou description (embedded mention of the booster email)

BEGIN;

-- 1. site_settings singleton
UPDATE site_settings
SET primary_contact_email = 'mcneilfootballboosters@gmail.com'
WHERE id = 1
  AND primary_contact_email = 'boosters@mcneilmavericks.org';

-- 2. SportsYou resource_links row description
UPDATE resource_links
SET description = REPLACE(
  description,
  'boosters@mcneilmavericks.org',
  'mcneilfootballboosters@gmail.com'
)
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%boosters@mcneilmavericks.org%';

COMMIT;

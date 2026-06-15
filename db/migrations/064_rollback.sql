-- 064_rollback.sql
-- Reverses 064, restoring the temporary Gmail placeholders.

BEGIN;

UPDATE site_settings
SET primary_contact_email = 'mcneilfootballboosters@gmail.com'
WHERE id = 1
  AND primary_contact_email = 'boosters@mcneilmavericks.org';

UPDATE resource_links
SET description = REPLACE(description, 'boosters@mcneilmavericks.org', 'mcneilfootballboosters@gmail.com')
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%boosters@mcneilmavericks.org%';

-- Board cards back to the shared Gmail placeholder (only the rows 064 set).
UPDATE board_members SET email_alias = 'mcneilfootballboosters@gmail.com'
WHERE year = '2026-27'
  AND email_alias IN (
    'president@mcneilmavericks.org',
    'treasurer@mcneilmavericks.org',
    'secretary@mcneilmavericks.org',
    'vicepresident@mcneilmavericks.org',
    'membership@mcneilmavericks.org',
    'boosters@mcneilmavericks.org'
  );

COMMIT;

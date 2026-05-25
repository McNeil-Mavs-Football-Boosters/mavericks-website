-- 047_rollback.sql
-- Reverses 047_resources_drop_news_add_mavmail_description.sql.
--
-- Re-inserts the News row with its 046-era values (captured via SELECT
-- before deletion) and sets MavMail description back to NULL.

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'communications',
  'News',
  '/news',
  'McNeil Mavericks football news and updates.',
  'newspaper',
  -1,
  true
);

UPDATE resource_links
SET description = NULL
WHERE label = 'MavMail'
  AND section = 'communications';

COMMIT;

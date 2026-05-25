-- 046_rollback.sql
-- Reverses 046_resources_add_news_and_mavmail.sql.

BEGIN;

DELETE FROM resource_links
WHERE section = 'communications'
  AND label IN ('MavMail', 'News')
  AND sort_order IN (-2, -1);

COMMIT;

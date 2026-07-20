-- 073_rollback.sql
-- Reverses 073_resources_add_mailing_list.sql by deleting the row by label.

BEGIN;

DELETE FROM resource_links
WHERE section = 'communications'
  AND label = 'Join Our Mailing List';

COMMIT;

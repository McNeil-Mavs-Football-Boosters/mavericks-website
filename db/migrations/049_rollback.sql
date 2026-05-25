-- 049_rollback.sql
-- Reverses 049_resources_add_facebook_parents_group.sql.

BEGIN;

DELETE FROM resource_links
WHERE url = 'https://www.facebook.com/groups/967201656648938';

COMMIT;

-- 047_resources_drop_news_add_mavmail_description.sql
--
-- Two changes in 'communications' section of resource_links:
--   1. Drop the standalone "News" entry added in 046. There is no /news
--      route planned; the link would 404.
--   2. Add a description to the MavMail row (was NULL in 046).
--
-- The "News & Communications" UI heading rename landed in code in
-- commit f11c5f4 + same-commit fix for "&" vs "and" consistency with
-- the other section headings (app/resources/page.tsx SECTION_ORDER);
-- no DB change needed for that.

BEGIN;

DELETE FROM resource_links
WHERE section = 'communications'
  AND label = 'News'
  AND url = '/news';

UPDATE resource_links
SET description = 'McNeil High School''s weekly newsletter. Published most Sundays at 5PM.'
WHERE label = 'MavMail'
  AND section = 'communications';

COMMIT;

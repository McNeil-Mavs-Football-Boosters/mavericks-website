-- 046_resources_add_news_and_mavmail.sql
--
-- Adds two entries to the resource_links 'communications' section so that
-- /news (now removed from top-level nav) and the weekly MavMail newsletter
-- are discoverable from the Forms & Links page (/resources).
--
-- The 'communications' section enum value stays as-is at the DB level; only
-- the UI heading rendered in app/resources/page.tsx flips to "News and
-- Communications" (hardcoded SECTION_ORDER, no schema change needed).
--
-- sort_order strategy: existing siblings are HUDL=1, SportsYou=2. New rows
-- use negative sort_order so they render first (ORDER BY ASC) WITHOUT
-- renumbering existing rows. MavMail=-2 (top), /news=-1 (second).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES
  ('communications', 'MavMail', 'https://roundrockisd.edurooms.com/newsletters/mcneil-high-school/newsletters/mavmail-sunday-may-24-2026', NULL, 'mail', -2, true),
  ('communications', 'News', '/news', 'McNeil Mavericks football news and updates.', 'newspaper', -1, true);

COMMIT;

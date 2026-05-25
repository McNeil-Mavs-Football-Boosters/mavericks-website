-- 049_resources_add_facebook_parents_group.sql
--
-- Adds one row to the resource_links 'communications' section: the
-- McNeil Mavericks Football Parents Facebook Group. Positioned at
-- sort_order=3 -- immediately below SportsYou (2). No renumbering of
-- existing rows needed; sort_order=3 was unused.
--
-- NOTE on naming: the table is resource_links (not resources) and the
-- column is section (an ENUM, not category). The DB enum value
-- 'communications' is unchanged; the UI heading "News & Communications"
-- is rendered by app/resources/page.tsx SECTION_ORDER.
--
-- icon_hint='facebook' is a new lowercase hint registered in
-- lib/resource-icons.tsx (inline SVG, since lucide-react v1.x dropped
-- brand glyphs for trademark reasons -- same pattern as Footer.tsx).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'communications',
  'McNeil Mavericks Football Parents (Facebook Group)',
  'https://www.facebook.com/groups/967201656648938',
  'This group is for parents of ALL McNeil High School football athletes to share information.',
  'facebook',
  3,
  true
);

COMMIT;

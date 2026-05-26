-- 051_resources_add_game_photos_clear_bag_mhs.sql
--
-- Adds three resource_links rows:
--   1. Game Photos (communications, sort_order=4) — family-sourced photo
--      doc; sibling to the Facebook Parents Group above it. New icon_hint
--      'photo' (registered in lib/resource-icons.tsx with a lucide Camera).
--   2. Clear Bag Policy (stadiums, sort_order=2) — RRISD district policy,
--      placed directly after Kelly Reeves Athletic Complex.
--   3. McNeil High School (resources, sort_order=1) — institutional link,
--      first entry in the Resources section (previously empty).

BEGIN;

INSERT INTO resource_links (section, sort_order, label, description, url, icon_hint, active)
VALUES
  (
    'communications',
    4,
    'Game Photos',
    'Game photos shared by McNeil Mavericks families.',
    'https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0/edit?tab=t.0#heading=h.gf4l39u0yuz6',
    'photo',
    true
  ),
  (
    'stadiums',
    2,
    'Clear Bag Policy',
    'Round Rock ISD clear bag requirements for athletic events.',
    'https://www.roundrockisd.org/page/clear-bag-policy',
    'external',
    true
  ),
  (
    'resources',
    1,
    'McNeil High School',
    'Official school website.',
    'https://mcneil.roundrockisd.org/',
    'external',
    true
  );

COMMIT;

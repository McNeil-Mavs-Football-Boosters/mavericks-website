-- 051_rollback.sql
-- Reverses 051_resources_add_game_photos_clear_bag_mhs.sql.

BEGIN;

DELETE FROM resource_links
WHERE url IN (
  'https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0/edit?tab=t.0#heading=h.gf4l39u0yuz6',
  'https://www.roundrockisd.org/page/clear-bag-policy',
  'https://mcneil.roundrockisd.org/'
);

COMMIT;

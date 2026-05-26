-- 052_rollback.sql
-- Reverses 052_resources_and_games_backfill.sql.

BEGIN;

-- Reverse 6 — location_url
UPDATE games SET location_url=NULL
WHERE year='2025-26' AND location IN ('KRAC', 'House Park', 'Dragon Stadium');

-- Reverse 5b — Hutto watch_url
UPDATE games SET watch_url=NULL
WHERE year='2025-26' AND team_level='varsity' AND opponent='Hutto High School';

-- Reverse 5a — varsity scores
UPDATE games SET result_status='scheduled', our_score=NULL, their_score=NULL
WHERE year='2025-26' AND team_level='varsity' AND opponent IN (
  'Weiss High School','Lake Belton High School','Westwood High School',
  'Round Rock High School','Stony Point High School','Vandegrift High School',
  'Vista Ridge High School','Cedar Ridge High School','Manor High School'
);

-- Reverse 4 — drop the new stadium rows
DELETE FROM resource_links
WHERE section='stadiums' AND label IN ('House Park', 'Dragon Stadium');

-- Reverse 3 — restore Clear Bag Policy
INSERT INTO resource_links (section, sort_order, label, description, url, icon_hint, active)
VALUES (
  'stadiums', 2, 'Clear Bag Policy',
  'Round Rock ISD clear bag requirements for athletic events.',
  'https://www.roundrockisd.org/page/clear-bag-policy',
  'external', true
);

-- Reverse 2 — KRAC rename
UPDATE resource_links SET label='Kelly Reeves Athletic Complex'
WHERE label='Kelly Reeves Athletic Complex (KRAC)';

-- Reverse 1 — HUDL move
UPDATE resource_links SET section='communications', sort_order=1
WHERE label='HUDL' AND section='resources';

COMMIT;

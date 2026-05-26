-- 052_resources_and_games_backfill.sql
--
-- 1. Move HUDL from News & Communications to Resources.
-- 2. Rename Kelly Reeves Athletic Complex → "Kelly Reeves Athletic Complex (KRAC)".
-- 3. Remove the Clear Bag Policy resource row; the /resources page now
--    renders it as a small subordinate link below the Stadiums list
--    (hardcoded against CLEAR_BAG_POLICY_URL in lib/constants.ts).
-- 4. Add House Park + Dragon Stadium stadium rows (addresses verified
--    via Round Rock ISD, Austin ISD, and TexasBob.com).
-- 5. Backfill 2025-26 varsity scores from MaxPreps (9 wins/losses on
--    finalized games; Hutto stays result_status='scheduled' with a
--    watch_url so the Result cell renders "Watch →" instead of em-dash).
-- 6. Populate games.location_url for games at KRAC / House Park /
--    Dragon Stadium across every team level.

BEGIN;

-- 1. HUDL move
UPDATE resource_links
SET section = 'resources', sort_order = 2
WHERE label = 'HUDL' AND section = 'communications';

-- 2. KRAC rename
UPDATE resource_links
SET label = 'Kelly Reeves Athletic Complex (KRAC)'
WHERE label = 'Kelly Reeves Athletic Complex' AND section = 'stadiums';

-- 3. Drop the Clear Bag Policy row (rendered as a subordinate link in code)
DELETE FROM resource_links
WHERE url = 'https://www.roundrockisd.org/page/clear-bag-policy';

-- 4. New stadium rows
INSERT INTO resource_links (section, sort_order, label, description, url, icon_hint, active) VALUES
  (
    'stadiums',
    2,
    'House Park',
    '1301 Shoal Creek Blvd, Austin, TX 78701. Austin ISD stadium hosting Anderson HS home football.',
    'https://www.google.com/maps/search/?api=1&query=1301+Shoal+Creek+Blvd%2C+Austin%2C+TX+78701',
    'external',
    true
  ),
  (
    'stadiums',
    3,
    'Dragon Stadium',
    '300 N Lake Creek Dr, Round Rock, TX 78681. Home of the Round Rock Dragons.',
    'https://www.google.com/maps/search/?api=1&query=300+N+Lake+Creek+Dr%2C+Round+Rock%2C+TX+78681',
    'external',
    true
  );

-- 5. 2025-26 varsity scores backfill (chronological)
UPDATE games SET result_status='final', our_score=28, their_score=56
WHERE year='2025-26' AND team_level='varsity' AND opponent='Weiss High School';

UPDATE games SET result_status='final', our_score=34, their_score=28
WHERE year='2025-26' AND team_level='varsity' AND opponent='Lake Belton High School';

UPDATE games SET result_status='final', our_score=70, their_score=45
WHERE year='2025-26' AND team_level='varsity' AND opponent='Westwood High School';

UPDATE games SET result_status='final', our_score=17, their_score=31
WHERE year='2025-26' AND team_level='varsity' AND opponent='Round Rock High School';

UPDATE games SET result_status='final', our_score=56, their_score=21
WHERE year='2025-26' AND team_level='varsity' AND opponent='Stony Point High School';

UPDATE games SET result_status='final', our_score=17, their_score=14
WHERE year='2025-26' AND team_level='varsity' AND opponent='Vandegrift High School';

UPDATE games SET result_status='final', our_score=45, their_score=42
WHERE year='2025-26' AND team_level='varsity' AND opponent='Vista Ridge High School';

UPDATE games SET result_status='final', our_score=35, their_score=38
WHERE year='2025-26' AND team_level='varsity' AND opponent='Cedar Ridge High School';

UPDATE games SET result_status='final', our_score=42, their_score=21
WHERE year='2025-26' AND team_level='varsity' AND opponent='Manor High School';

-- Last varsity game — Hutto. Leave as scheduled with no score; set
-- watch_url so the Result cell renders "Watch →" instead of em-dash.
UPDATE games SET watch_url='https://www.youtube.com/@iHSFan'
WHERE year='2025-26' AND team_level='varsity' AND opponent='Hutto High School';

-- Aug 21 Anderson scrimmage left as result_status='scheduled' with no
-- score. SA1 research didn't surface a MaxPreps score for this game;
-- per the original seed build log (032), it appears to have been a
-- non-district season opener / scrimmage.

-- 6. location_url backfill — all team levels, all 2025-26 games at the
-- three stadiums we know about. Same URL for every game at the same
-- venue; no schema change needed (column already exists).
UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=10211+W+Parmer+Ln%2C+Austin%2C+TX+78717'
WHERE year='2025-26' AND location='KRAC';

UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=1301+Shoal+Creek+Blvd%2C+Austin%2C+TX+78701'
WHERE year='2025-26' AND location='House Park';

UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=300+N+Lake+Creek+Dr%2C+Round+Rock%2C+TX+78681'
WHERE year='2025-26' AND location='Dragon Stadium';

COMMIT;

-- Migration 029: TEST DATA. Lights up the public roster render with the
-- 2025-26 MaxPreps varsity snapshot, attached to the 2026-27 varsity
-- roster row so the page has real-looking content for staging review.
--
-- Remove before public cutover. Tracked in followups.md.
-- Cleanup path: DELETE FROM players WHERE roster_id =
--   (SELECT id FROM rosters WHERE year='2026-27' AND team_level='varsity'
--    AND team_designation IS NULL AND active=true);
--
-- Source: docs/mcneil_varsity_roster_2025-26.txt (27 players).

BEGIN;

INSERT INTO players (
  roster_id,
  jersey_number, first_name, last_name,
  position, grade, height, weight,
  sort_order, active
)
SELECT
  r.id,
  v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, v.height, v.weight,
  v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('0',  'Aden',     'Taylor',     NULL,      'Sr.', '5''11"', 175, 1),
  ('1',  'Bryce',    'Wilson',     'K, P',    'Sr.', '6''2"',  220, 2),
  ('2',  'Sean',     'Crowe',      'FS',      'Sr.', NULL,     NULL::int, 3),
  ('3',  'Brian',    'Perkins',    'WR, DB',  'Sr.', NULL,     NULL::int, 4),
  ('4',  'Isaiah',   'Jones',      'CB, WR',  'Jr.', '6''2"',  185, 5),
  ('5',  'Jarell',   'Gary Jr',    'WR, QB',  'Sr.', '6''0"',  190, 6),
  ('7',  'Ja Corian','Hubbard',    'DL, RB',  'Sr.', '6''2"',  250, 7),
  ('8',  'Marshall', 'Holland',    'MLB, OLB','Sr.', '5''10"', 215, 8),
  ('9',  'Zach',     'Christie',   'WR',      'Sr.', '6''2"',  188, 9),
  ('10', 'Jadon',    'Sultz',      'QB',      'Sr.', '6''1"',  200, 10),
  ('11', 'Calvin',   'Cervini',    'QB, CB',  'Sr.', '6''4"',  180, 11),
  ('14', 'DJ',       'Vasquez',    'DB',      'Sr.', NULL,     NULL::int, 12),
  ('15', 'Tyson',    'Cox',        'OLB, SS', 'Jr.', '5''10"', 190, 13),
  ('18', 'Kaden',    'Kearney',    'DB',      'So.', NULL,     NULL::int, 14),
  ('20', 'Keyvon',   'Myers',      'CB',      'Sr.', '6''0"',  170, 15),
  ('21', 'Johnny',   'McFarland',  'DB',      'Sr.', NULL,     NULL::int, 16),
  ('22', 'Adien',    'Murray',     'DB',      'Sr.', NULL,     NULL::int, 17),
  ('23', 'Zylen',    'Hall',       'RB',      'Jr.', '5''7"',  155, 18),
  ('24', 'Malachi',  'Golden',     'DB',      'Sr.', NULL,     NULL::int, 19),
  ('25', 'Jamal',    'Harris',     'RB',      'Sr.', NULL,     NULL::int, 20),
  ('32', 'Michael',  'Jones',      'OLB',     'Sr.', '6''1"',  190, 21),
  ('34', 'Skyler',   'Eaves',      'OLB',     'Sr.', '6''0"',  172, 22),
  ('38', 'Ford',     'Askins',     'LB',      'Jr.', NULL,     NULL::int, 23),
  ('42', 'Jacorian', 'Hubbard',    'DE',      'Sr.', '6''0"',  200, 24),
  ('46', 'Nkume',    'Nwosu',      'DL',      'Sr.', NULL,     NULL::int, 25),
  ('53', 'Isaiah',   'Escalante',  'C, DE',   'Sr.', '6''0"',  208, 26),
  ('82', 'Bowen',    'Wheatley',   'TE',      'Sr.', '6''3"',  215, 27)
) AS v(jersey_number, first_name, last_name, position, grade, height, weight, sort_order)
WHERE r.year = '2026-27'
  AND r.team_level = 'varsity'
  AND r.team_designation IS NULL
  AND r.active = true;

COMMIT;

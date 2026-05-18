-- Migration 031: TEST DATA for the 2025-26 review period.
-- Adds the JV (65 players), Freshman Green (19), and Freshman Blue (22)
-- rosters from the 2025 PDFs in docs/. Creates the Freshman Blue
-- rosters row (Green already seeded by 018 + 019). Flips
-- site_settings.freshman_has_blue=true so the Blue page renders and
-- the header dropdown shows the Blue entry.
--
-- 8 freshman players are uncolored in the source PDF (no Green/Blue
-- assignment). They are NOT seeded; flagged in followups.md for coach
-- clarification. 1 freshman row in the PDF has neither jersey# nor
-- name (corrupt source row) — skipped.
--
-- Class column: source values 10 and 11 map to "So." and "Jr." for
-- display consistency with the varsity seed. Freshman = "Fr.".
--
-- Position: stored verbatim from source (e.g., "WR/DB", "OL/DL").
-- Height/weight not provided by source -> NULL.
--
-- Cleanup before public cutover:
--   DELETE FROM players WHERE roster_id IN (
--     SELECT id FROM rosters WHERE year='2025-26' AND team_level IN ('jv','freshman')
--   );
--   DELETE FROM rosters WHERE year='2025-26' AND team_level='freshman' AND team_designation='Blue';

BEGIN;

-- 1. Add the Freshman Blue rosters row (Green already exists from migration 018+019).
INSERT INTO rosters (year, team_level, team_designation, body, source_note, active)
VALUES ('2025-26', 'freshman', 'Blue', '', 'Awaiting roster from coaching staff', true);

-- 2. Flip the Blue flag so /roster/freshman/blue + /schedule/games/freshman/blue render.
UPDATE site_settings SET freshman_has_blue = true WHERE freshman_has_blue = false;

-- 3. JV roster: 65 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('0',  'Kees',                'Glinski',          'TE',       'Jr.',  1),
  ('1',  'Jace',                'Servantez',        'QB',       'So.',  2),
  ('2',  'Case',                'Keough',           'DB',       'So.',  3),
  ('3',  'Evan',                'Vest',             'DB',       'Jr.',  4),
  ('4',  'Hudson',              'Cronin',           'WR',       'So.',  5),
  ('5',  'Cicero',              'Stroman',          'DL',       'So.',  6),
  ('6',  'Silas',               'Carter',           'DB',       'So.',  7),
  ('7',  'Kieran',              'Jalbert',          'TE',       'So.',  8),
  ('8',  'Orion',               'Covault',          'QB',       'Jr.',  9),
  ('9',  'Aiden',               'Creque',           'WR',       'Jr.', 10),
  ('10', 'Keston',              'Variste',          'WR',       'So.', 11),
  ('11', 'Angel',               'Gudino De Leon',   'LB',       'Jr.', 12),
  ('12', 'Jatavius',            'Washington',       'QB',       'Jr.', 13),
  ('13', 'Eli',                 'Weaver',           'DB',       'Jr.', 14),
  ('14', 'Alonzo',              'Mata',             'WR',       'So.', 15),
  ('15', 'Hendrix',             'Boston',           'DB',       'Jr.', 16),
  ('16', 'Logan',               'Moeller',          'QB',       'So.', 17),
  ('17', 'Jude',                'Montez',           'WR',       'Jr.', 18),
  ('18', 'Ka''Darious',         'Montgomery',       'DB',       'So.', 19),
  ('19', 'Owen',                'Baumann',          'DB',       'So.', 20),
  ('20', 'Chance',              'Woodward',         'WR',       'Jr.', 21),
  ('21', 'Gabe',                'Parker',           'WR',       'So.', 22),
  ('22', 'Akmal',               'Waqif',            'LB',       'So.', 23),
  ('23', 'Omar',                'Aviles',           'LB',       'So.', 24),
  ('24', 'Tramaurie',           'Mayweather',       'WR',       'Jr.', 25),
  ('25', 'Owen',                'Mazorra',          'WR',       'So.', 26),
  ('26', 'Mcharo',              'Criswell',         'RB',       'Jr.', 27),
  ('27', 'Richardo',            'Gonzalez jr.',     'DB',       'So.', 28),
  ('28', 'Michael',              'Sieber',          'K',        'Jr.', 29),
  ('30', 'Ryan',                 'Amin',            'LB',       'Jr.', 30),
  ('31', 'Jordan',               'Deshay',          'RB',       'So.', 31),
  ('32', 'Aston',                'Sampayo',         'DB',       'So.', 32),
  ('33', 'Zji''Sean',            'Thomas',          'WR',       'So.', 33),
  ('34', 'Reid',                 'Gordon',          'DB',       'So.', 34),
  ('35', 'Ben',                  'Eaton',           'DB',       'So.', 35),
  ('36', 'Ford',                 'Askins',          'LB',       'Jr.', 36),
  ('37', 'Dylan',                'Woods',           'RB',       'Jr.', 37),
  ('38', 'Maxwell',              'Leger',           'DB',       'So.', 38),
  ('40', 'Akiereon',             'Chatman',         'DB',       'So.', 39),
  ('42', 'Quamera',              'Sutherland',      'LB',       'Jr.', 40),
  ('43', 'Aymane',               'El Anssari',      'K',        'Jr.', 41),
  ('45', 'James',                'Evans',           'DL',       'Jr.', 42),
  ('46', 'Oliver',               'Weisbrod',        'LB',       'So.', 43),
  ('48', 'Zackary',              'Hauser',          'DL',       'Jr.', 44),
  ('51', 'Joaquin',              'Mata',            'DL',       'Jr.', 45),
  ('52', 'Montana',              'Burks',           'LB',       'Jr.', 46),
  ('54', 'Nathan',               'Park',            'DL',       'So.', 47),
  ('55', 'Jayden',               'Fabien',          'DL',       'So.', 48),
  ('56', 'Juan',                 'Ramirez',         'OL',       'So.', 49),
  ('61', 'Gianni',               'Aviles',          'DL',       'Jr.', 50),
  ('62', 'Garrett',              'Root',            'OL',       'Jr.', 51),
  ('63', 'Leonardo',             'Soto',            'OL',       'Jr.', 52),
  ('66', 'Aiden',                'Ross',            'OL',       'So.', 53),
  ('70', 'Jackson',              'Miller',          'DL',       'So.', 54),
  ('71', 'D''Zion',              'Taylor',          'OL',       'So.', 55),
  ('72', 'Daniel',               'Christensen',     'OL',       'So.', 56),
  ('75', 'Preston',              'Higgins',         'OL',       'So.', 57),
  ('78', 'Wesley',               'Davis',           'OL',       'So.', 58),
  ('79', 'Soumith',              'Veeragoni',       'OL',       'So.', 59),
  ('80', 'Rashawn',              'McDowell',        'WR',       'So.', 60),
  ('81', 'Amery',                'Schoepflin',      'TE',       'Jr.', 61),
  ('82', 'Orion',                'Smith',           'WR',       'So.', 62),
  ('83', 'Brendyn',              'Brown',           'WR',       'Jr.', 63),
  ('86', 'Tramaurie',            'Mayweather',      'TE',       'Jr.', 64),
  ('88', 'Derrick',              'WIlliams',        'DL',       'So.', 65)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'jv'
  AND r.team_designation IS NULL
  AND r.active = true;

-- 4. Freshman Green: 19 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('1',  'Brayden',  'Norman',                'WR/DB', 'Fr.',  1),
  ('2',  'Ade',      'Carter',                'WR/DB', 'Fr.',  2),
  ('5',  'Kai',      'Brito',                 'QB/DB', 'Fr.',  3),
  ('6',  'William',  'Miller',                'QB/DB', 'Fr.',  4),
  ('7',  'Matheo',   'Ramirez-Escamilla',     'QB/DB', 'Fr.',  5),
  ('8',  'Josiah',   'Scott',                 'WR/DB', 'Fr.',  6),
  ('11', 'TreyVon',  'Cargill',               'WR/DB', 'Fr.',  7),
  ('12', 'Jeremy',   'Powell',                'TE/LB', 'Fr.',  8),
  ('13', 'Jeramiyah','Harris',                'RB/LB', 'Fr.',  9),
  ('15', 'TK',       'Keller',                'RB/LB', 'Fr.', 10),
  ('20', 'Antonio',  'Showels',               'WR/LB', 'Fr.', 11),
  ('26', 'Remiel',   'Soto',                  'TE/DB', 'Fr.', 12),
  ('30', 'Logan',    'Gurrola',               'WR/LB', 'Fr.', 13),
  ('38', 'Anjrue',   'Williams',              'QB/LB', 'Fr.', 14),
  ('52', 'Caleb',    'Woodward',              'OL/DL', 'Fr.', 15),
  ('67', 'Caleb',    'Cox',                   'OL/DL', 'Fr.', 16),
  ('75', 'Charles',  'Lewis',                 'OL/DL', 'Fr.', 17),
  ('76', 'Jace',     'Hicks',                 'OL/DL', 'Fr.', 18),
  ('84', 'Jake',     'Thomas',                'WR/DB', 'Fr.', 19)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Green'
  AND r.active = true;

-- 5. Freshman Blue: 22 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('9',  'Zane',     'Valenzuela',            'WR/DB', 'Fr.',  1),
  ('10', 'Jake',     'Saenz',                 'WR/DB', 'Fr.',  2),
  ('17', 'Owen',     'Richardson',            'WR/DB', 'Fr.',  3),
  ('18', 'Jackson',  'James',                 'WR/DB', 'Fr.',  4),
  ('21', 'Bryant',   'Smith',                 'RB/DB', 'Fr.',  5),
  ('22', 'Michael',  'Menchaca',              'WR/DB', 'Fr.',  6),
  ('23', 'Dante',    'McBeath',               'RB/LB', 'Fr.',  7),
  ('25', 'Angel',    'Meza',                  'RB/DL', 'Fr.',  8),
  ('28', 'Jasiah',   'Harris',                'WR/DB', 'Fr.',  9),
  ('33', 'Eli',      'Thrift',                'WR/DB', 'Fr.', 10),
  ('35', 'Ricky',    'Brown',                 'WR/DB', 'Fr.', 11),
  ('36', 'Isaac',    'Chandy',                'WR/DB', 'Fr.', 12),
  ('40', 'Gabriel',  'Berney',                'TE/DB', 'Fr.', 13),
  ('44', 'Iger',     'Mallvichko',            'TE/LB', 'Fr.', 14),
  ('45', 'Da''Mauri','Barfield',              'RB/DB', 'Fr.', 15),
  ('51', 'Jayden',   'Harris',                'OL/DL', 'Fr.', 16),
  ('54', 'Joseph',   'Bowles',                'OL/DL', 'Fr.', 17),
  ('60', 'Isaiah',   'Arias-Faulkner',        'OL/DL', 'Fr.', 18),
  ('61', 'Leland',   'Boston',                'OL/LB', 'Fr.', 19),
  ('77', 'Kaeden',   'Frazier',               'OL/DL', 'Fr.', 20),
  ('81', 'Alex',     'Pugliese',              'WR/DB', 'Fr.', 21),
  ('85', 'Riley',    'Cortez',                'WR/DB', 'Fr.', 22)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Blue'
  AND r.active = true;

COMMIT;

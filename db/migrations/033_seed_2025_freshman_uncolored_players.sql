-- Migration 033: Add the 8 freshman players that had no Green/Blue
-- color fill in the source PDF, after coach clarification from Jeremy.
--
-- Assignment (per Jeremy 2026-05-17):
--   Green: #4 Conan Shin, #71 Jaxon Pelosi, #73 Favor Omagbon  (+3 -> 22 total)
--   Blue:  #19 Lamonte Brown, #53 Augustus Cocke, #55 Jaye Solages,
--          #63 Mark Llamas, #72 Brennan McCallister             (+5 -> 27 total)
--
-- Total freshman seeded across Green + Blue: 49 (matches the named
-- count from docs/2025 McNeil Football Rosters - Freshmen.pdf).
--
-- sort_order values are picked to TIE with the preceding existing
-- player on the roster, so the PlayerTable component's secondary
-- jersey-ascending sort drops each new player into the right slot
-- without requiring an UPDATE of existing rows.
--
-- Still skipped: the corrupt PDF row with no jersey# and no name
-- (position WR/LB, grade 9 only). Tracked in followups.md.

BEGIN;

-- Freshman Green additions (3).
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('4',  'Conan',  'Shin',    'RB/DB', 'Fr.',  2),   -- between #2 Carter (sort 2) and #5 Brito (sort 3)
  ('71', 'Jaxon',  'Pelosi',  'OL/DL', 'Fr.', 16),   -- between #67 Cox (sort 16) and #75 Lewis (sort 17)
  ('73', 'Favor',  'Omagbon', 'OL/DL', 'Fr.', 16)    -- between #71 Pelosi (sort 16) and #75 Lewis (sort 17)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Green'
  AND r.active = true;

-- Freshman Blue additions (5).
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('19', 'Lamonte',  'Brown',        'WR/DB', 'Fr.',  4),   -- between #18 James (sort 4) and #21 Smith (sort 5)
  ('53', 'Augustus', 'Cocke',        'OL/DL', 'Fr.', 16),   -- between #51 J. Harris (sort 16) and #54 Bowles (sort 17)
  ('55', 'Jaye',     'Solages',      'OL/DL', 'Fr.', 17),   -- between #54 Bowles (sort 17) and #60 Arias-Faulkner (sort 18)
  ('63', 'Mark',     'Llamas',       'OL/LB', 'Fr.', 19),   -- between #61 Boston (sort 19) and #77 Frazier (sort 20)
  ('72', 'Brennan',  'McCallister',  'OL/DL', 'Fr.', 19)    -- between #61 Boston (sort 19) and #77 Frazier (sort 20)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Blue'
  AND r.active = true;

COMMIT;

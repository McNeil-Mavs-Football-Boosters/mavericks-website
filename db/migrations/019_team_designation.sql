-- Migration 019: Add team_designation to games and rosters; replace rosters uniqueness
-- with a COALESCE-based unique index (varsity/JV use NULL, freshman uses 'Green'/'Blue').

BEGIN;

ALTER TABLE games ADD COLUMN team_designation text;
ALTER TABLE rosters ADD COLUMN team_designation text;

ALTER TABLE rosters DROP CONSTRAINT rosters_year_team_level_key;

CREATE UNIQUE INDEX idx_rosters_year_level_designation
  ON rosters (year, team_level, COALESCE(team_designation, ''));

UPDATE rosters SET team_designation = 'Green'
  WHERE year = '2026-27' AND team_level = 'freshman';

COMMIT;

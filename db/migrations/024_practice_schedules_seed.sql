-- Migration 024: Seed practice_schedules with three team-level stubs for 2026-27.

INSERT INTO practice_schedules (year, team_level, body, source_note) VALUES
  ('2026-27', 'varsity',  '', 'Awaiting practice schedule from coaching staff'),
  ('2026-27', 'jv',       '', 'Awaiting practice schedule from coaching staff'),
  ('2026-27', 'freshman', '', 'Awaiting practice schedule from coaching staff');

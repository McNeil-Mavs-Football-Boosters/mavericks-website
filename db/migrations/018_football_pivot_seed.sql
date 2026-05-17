-- Migration 018: Football pivot seed data (rosters stubs, Coach Wallin, resource_links scaffolding)

-- Block 1: rosters — three stubs for 2026-27.
-- team_designation column does not exist yet (added in 019); freshman 'Green'
-- designation will be backfilled there.
INSERT INTO rosters (year, team_level, body, source_note) VALUES
  ('2026-27', 'varsity',  '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'jv',       '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'freshman', '', 'Awaiting roster from coaching staff');

-- Block 2: coaches — Coach Wallin (still on staff, no longer head coach).
INSERT INTO coaches (year, name, role, role_category, sort_order, active) VALUES
  ('2026-27', 'Coach Wallin', 'Position Coach', 'position_coach', 10, true);

-- Block 3: resource_links — section scaffolding plus known-good rows.
-- SportsYou URL/description per schema_v2_addendum.md section 4 (not the original '#').
INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order) VALUES
  -- Registration & Forms
  ('registration_forms', 'Aktivate (Athletic Registration)', 'https://www.aktivate.com/', 'Required online registration for all athletes. Replaces the old RankOne system.', 'external', 1),
  ('registration_forms', 'UIL Forms', 'https://www.uiltexas.org/athletics/forms', 'University Interscholastic League required forms for participation.', 'external', 2),
  ('registration_forms', 'RRISD Athletic Forms', 'https://roundrockisd.org/athletics', 'Round Rock ISD athletic department forms and policies.', 'external', 3),
  -- Communications
  ('communications', 'HUDL', 'https://www.hudl.com/jointeam', 'Team video and stats platform. Team code provided by coaching staff.', 'external', 1),
  ('communications', 'SportsYou (Team Messaging)', 'https://www.sportsyou.com/', 'Team messaging app for parents and players. Use the access code from the SportsYou invite page in the SE capture, or contact the booster club at boosters@mcneilmavericks.org.', 'external', 2),
  -- Stadiums
  ('stadiums', 'Kelly Reeves Athletic Complex', 'https://maps.google.com/?q=Kelly+Reeves+Athletic+Complex+Round+Rock+TX', 'McNeil home games. 10211 W Parmer Ln, Austin, TX 78717.', 'external', 1);

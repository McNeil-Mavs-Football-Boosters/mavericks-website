-- Migration 057: seed the real 2026-27 schedule (40 rows) + 2026-27 schedule-PDF
-- stub roster rows. Source: docs/Round Rock McNeil 2026 - corrected.pdf
-- (Jonathan Cruz->Jerry Gardner; Senior Night moved to V Sep 4 Lake Belton).
-- Verified: weekdays vs 2026 calendar (0 mismatches) + independent cell-by-cell
-- PDF check (CLEAN). District '*' stripped from opponent names (no column),
-- matching migration 032. Senior Night/Homecoming carried in notes.
-- Aug 13 + Aug 20 (TBD-kickoff preseason games) are intentionally OMITTED from
-- the site per Jeremy; they remain on the downloadable PDF only.
-- All games Aug-Oct 2026 = CDT; PG handles the tz literal.
--
-- Print View PDF: schedule game pages read schedule_pdf_storage_path off a
-- rosters row matched on (current_schedule_year, level, designation). Real
-- rosters live at 2025-26, so 4 stub rosters rows at 2026-27 carry ONLY the
-- schedule PDF path (no players); roster *pages* read current_year (2025-26)
-- and never see these stubs.
--
-- Cleanup when admin CRUD lands:
--   DELETE FROM games WHERE year='2026-27';
--   DELETE FROM rosters WHERE year='2026-27' AND pdf_storage_path IS NULL;

BEGIN;

INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url, game_date, location, location_url,
  home_or_away, result_status, our_score, their_score,
  watch_url, notes, featured
) VALUES
  -- VARSITY (10) — Aug 13/20 scrimmages omitted from site (on PDF only)
  ('2026-27', 'varsity', NULL, 'Austin Bowie High School', NULL, '2026-08-28 19:00 America/Chicago', 'Burger Stadium', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Lake Belton High School', NULL, '2026-09-04 19:00 America/Chicago', 'Dragon Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Senior Night', false),
  ('2026-27', 'varsity', NULL, 'Rouse High School', NULL, '2026-09-11 19:00 America/Chicago', 'Gupton', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Vista Ridge High School', NULL, '2026-09-18 19:00 America/Chicago', 'Gupton', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Lake Travis High School', NULL, '2026-09-24 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Cedar Ridge High School', NULL, '2026-10-02 19:00 America/Chicago', 'KRAC', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Stony Point High School', NULL, '2026-10-09 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Westlake High School', NULL, '2026-10-16 19:00 America/Chicago', 'Chaparral', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Round Rock High School', NULL, '2026-10-23 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Homecoming', false),
  ('2026-27', 'varsity', NULL, 'Westwood High School', NULL, '2026-10-30 19:00 America/Chicago', 'KRAC', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- JV (10)
  ('2026-27', 'jv', NULL, 'Austin Bowie High School', NULL, '2026-08-27 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Lake Belton High School', NULL, '2026-09-03 18:00 America/Chicago', 'Lake Belton HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Rouse High School', NULL, '2026-09-10 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Vista Ridge High School', NULL, '2026-09-17 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Lake Travis High School', NULL, '2026-09-23 18:00 America/Chicago', 'Lake Travis HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Cedar Ridge High School', NULL, '2026-10-01 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Stony Point High School', NULL, '2026-10-08 18:00 America/Chicago', 'Stony Point HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Westlake High School', NULL, '2026-10-15 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Round Rock High School', NULL, '2026-10-22 18:00 America/Chicago', 'Dragon Stadium', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Westwood High School', NULL, '2026-10-29 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- FRESHMAN BLUE (10) @5:00pm
  ('2026-27', 'freshman', 'Blue', 'Austin Bowie High School', NULL, '2026-08-27 17:00 America/Chicago', 'Bowie HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Lake Belton High School', NULL, '2026-09-03 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Rouse High School', NULL, '2026-09-10 17:00 America/Chicago', 'Rouse HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Vista Ridge High School', NULL, '2026-09-17 17:00 America/Chicago', 'Vista Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Lake Travis High School', NULL, '2026-09-23 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Cedar Ridge High School', NULL, '2026-10-01 17:00 America/Chicago', 'Cedar Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Stony Point High School', NULL, '2026-10-08 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Westlake High School', NULL, '2026-10-15 17:00 America/Chicago', 'Westlake HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Round Rock High School', NULL, '2026-10-22 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Westwood High School', NULL, '2026-10-29 17:00 America/Chicago', 'Westwood HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- FRESHMAN GREEN (10) @6:30pm
  ('2026-27', 'freshman', 'Green', 'Austin Bowie High School', NULL, '2026-08-27 18:30 America/Chicago', 'Bowie HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Lake Belton High School', NULL, '2026-09-03 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Rouse High School', NULL, '2026-09-10 18:30 America/Chicago', 'Rouse HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Vista Ridge High School', NULL, '2026-09-17 18:30 America/Chicago', 'Vista Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Lake Travis High School', NULL, '2026-09-23 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Cedar Ridge High School', NULL, '2026-10-01 18:30 America/Chicago', 'Cedar Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Stony Point High School', NULL, '2026-10-08 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Westlake High School', NULL, '2026-10-15 18:30 America/Chicago', 'Westlake HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Round Rock High School', NULL, '2026-10-22 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Westwood High School', NULL, '2026-10-29 18:30 America/Chicago', 'Westwood HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false);

INSERT INTO rosters (year, team_level, team_designation, active, schedule_pdf_storage_path)
VALUES
  ('2026-27', 'varsity',  NULL,    true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'jv',       NULL,    true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'freshman', 'Green', true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'freshman', 'Blue',  true, 'documents/schedules/2026-27.pdf');

COMMIT;

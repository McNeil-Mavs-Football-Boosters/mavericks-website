-- 157_rollback.sql
--
-- Undo 157_seed_2026_varsity_roster.sql: remove the 45 seeded 2026-27 varsity
-- players and clear the source_note that 157 wrote.
--
-- ⚠️ DELETES BY ROSTER, NOT BY NAME. If anyone has hand-added or hand-edited a
-- player on this roster since 157 ran, this takes those rows too. That is the
-- right behaviour for a seed rollback -- the roster returns to the empty stub
-- state 057 left it in -- but check before running it mid-season.
--
-- The rosters row itself is NOT deleted. It predates 157 (created by 057) and
-- carries schedule_pdf_storage_path, which the /schedule/games/varsity Print
-- View reads. Deleting it would break the schedule PDF link, which has nothing
-- to do with the roster.
--
-- pdf_storage_path is cleared as well, because it is set alongside this seed
-- (roster PDF upload) and a Print View button pointing at a roster with no
-- players is worse than no button. PrintViewLink renders nothing on NULL.

begin;

delete from players p
 using rosters r
 where p.roster_id = r.id
   and r.year = '2026-27'
   and r.team_level = 'varsity'
   and r.team_designation is null;

update rosters
   set source_note = null,
       pdf_storage_path = null
 where year = '2026-27'
   and team_level = 'varsity'
   and team_designation is null;

commit;

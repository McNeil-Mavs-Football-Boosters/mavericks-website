-- 232_roster_pdfs_oct8.sql
--
-- Print View for all three 2026-27 rosters, after 231's player changes.
--   varsity  r7 -> documents/rosters/varsity-2026-r8.pdf  (workbook + make-varsity-roster-pdf.py;
--            #42/#46 added, blocks now 26/25 like Coach's Oct 8 sheet, row padding 4 -> 3pt to stay one page)
--   jv       jv-2026.pdf -> documents/rosters/jv-2026-r2.pdf
--   freshman r2 -> documents/rosters/freshman-2026-r3.pdf
-- JV and freshman were the coaches' own exports until now. Coach's Oct 8 files were Gmail
-- printouts (personal addresses in the header, JV without numbers), so per Jeremy ("just fix the
-- current pdfs") both are rebuilt in their current layouts from the players table by
-- MavericksWebsite/scripts/make-subvarsity-roster-pdf.py. New filenames per 158; all three
-- uploaded and sha256-identical on the round trip. Old objects stay in the bucket for the rollback.
--
-- DB-ONLY, NO DEPLOY. Rollback: 232_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters where year = '2026-27' and (
       (team_level = 'varsity' and pdf_storage_path = 'documents/rosters/varsity-2026-r7.pdf')
    or (team_level = 'jv' and pdf_storage_path = 'documents/rosters/jv-2026.pdf')
    or (team_level = 'freshman' and team_designation = 'Green' and pdf_storage_path = 'documents/rosters/freshman-2026-r2.pdf'));
  if n <> 3 then raise exception 'expected the 3 rosters on their pre-232 PDFs, found %', n; end if;

  -- the PDFs were generated from 231's counts; refuse to point at them otherwise (186's rule)
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 51 then raise exception 'varsity is %, PDF says 51', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 23 then raise exception 'jv is %, PDF says 23', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green';
  if n <> 51 then raise exception 'freshman is %, PDF says 51', n; end if;
end $$;

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r8.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r2.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/freshman-2026-r3.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green';

commit;

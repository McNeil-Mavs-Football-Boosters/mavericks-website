-- 251_roster_pdfs_staff_doyle_gerard.sql
--
-- Print View staff credit block, varsity + JV (Jeremy 2026-10-20):
--   * add Ryan Doyle (OL coach, on /coaches since 075) to Assistant Coaches, after Umberger
--   * "Principal - Dr. Mack Eagleton" -> "Interim Principal - Dr. Byron Gerard"
--   varsity r9 -> documents/rosters/varsity-2026-r10.pdf  (workbook A30 edited, r9 workbook + PDF archived)
--   jv      r2 -> documents/rosters/jv-2026-r3.pdf        (STAFF_LINES in make-subvarsity-roster-pdf.py)
-- Freshman PDF has no staff block, untouched. Players unchanged (51 / 23).
-- New filenames per 158; both uploaded, sha256-identical round trip. Old objects stay for the rollback.
--
-- DB-ONLY, NO DEPLOY. Rollback: 251_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters where year = '2026-27' and (
       (team_level = 'varsity' and pdf_storage_path = 'documents/rosters/varsity-2026-r9.pdf')
    or (team_level = 'jv' and pdf_storage_path = 'documents/rosters/jv-2026-r2.pdf'));
  if n <> 2 then raise exception 'expected varsity r9 + jv r2, found %', n; end if;

  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 51 then raise exception 'varsity is %, PDF says 51', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 23 then raise exception 'jv is %, PDF says 23', n; end if;
end $$;

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r10.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r3.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;

commit;

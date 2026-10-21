-- 253_roster_pdfs_trainer_florez_cook.sql
--
-- Print View staff block, varsity + JV (Jeremy 2026-10-20, "coach spells shit wrong all the time"):
--   "Trainers - Maggie Flores-Cook" -> "Head Athletic Trainer - Maggie Florez-Cook"
-- Matches /coaches (252) and the RRISD athletics article.
--   varsity r10 -> documents/rosters/varsity-2026-r11.pdf  (workbook A30; r10 workbook + PDF archived)
--   jv      r3  -> documents/rosters/jv-2026-r4.pdf        (STAFF_LINES in make-subvarsity-roster-pdf.py)
-- Text diff vs the previous PDFs is exactly that line. sha256 round trip OK.
--
-- DB-ONLY, NO DEPLOY. Rollback: 253_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters where year = '2026-27' and (
       (team_level = 'varsity' and pdf_storage_path = 'documents/rosters/varsity-2026-r10.pdf')
    or (team_level = 'jv' and pdf_storage_path = 'documents/rosters/jv-2026-r3.pdf'));
  if n <> 2 then raise exception 'expected varsity r10 + jv r3, found %', n; end if;

  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 51 then raise exception 'varsity is %, PDF says 51', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 23 then raise exception 'jv is %, PDF says 23', n; end if;
end $$;

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r11.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r4.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;

commit;

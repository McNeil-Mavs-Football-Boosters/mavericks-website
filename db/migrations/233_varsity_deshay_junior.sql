-- 233_varsity_deshay_junior.sql
--
-- #32 Jordan Deshay is a junior, not a senior (Jeremy 2026-10-08). Every coaches' export
-- had CLASS 12; his 2025-26 row is JV So., which agrees with Jr. now.
-- PDF half: workbook cell H5 12 -> 11 (r8 workbook + PDF archived), regenerated, diffed
-- against r8 (exactly that line), uploaded documents/rosters/varsity-2026-r9.pdf, sha256 OK.
-- ⚠️ Add to the export overrides (now seven): Deshay Jr.
--
-- DB-ONLY, NO DEPLOY. Rollback: 233_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and p.jersey_number = '32' and p.last_name = 'Deshay' and p.grade = 'Sr.';
  if n <> 1 then raise exception 'expected #32 Deshay Sr., found % (already applied?)', n; end if;
  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and pdf_storage_path = 'documents/rosters/varsity-2026-r8.pdf';
  if n <> 1 then raise exception 'varsity roster not on r8'; end if;
end $$;

update players p set grade = 'Jr.', updated_at = now() from rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and p.jersey_number = '32' and p.last_name = 'Deshay';

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r9.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

commit;

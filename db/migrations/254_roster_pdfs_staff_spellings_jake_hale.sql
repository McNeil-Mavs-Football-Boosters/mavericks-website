-- 254_roster_pdfs_staff_spellings_jake_hale.sql
--
-- Jeremy 2026-10-20:
--   Print View staff block, varsity + JV: "Barret Matthews" -> "Barrett Matthews",
--   "Nicolas Edwards" -> "Nicholas Edwards" (both per their RRISD email addresses).
--     varsity r11 -> documents/rosters/varsity-2026-r12.pdf  (workbook A30; r11 archived)
--     jv      r4  -> documents/rosters/jv-2026-r5.pdf        (STAFF_LINES; r4 archived)
--   Whitespace-normalised text diff is exactly those two names. sha256 round trip OK.
--   /coaches: "Michael Hale" -> "Jake Hale". Coach's roster sheet says Jake; Jeremy: "he goes
--   by Jake i think". Email stays Michael_Hale@ (that is the district address).
--
-- DB-ONLY, NO DEPLOY. Rollback: 254_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters where year = '2026-27' and (
       (team_level = 'varsity' and pdf_storage_path = 'documents/rosters/varsity-2026-r11.pdf')
    or (team_level = 'jv' and pdf_storage_path = 'documents/rosters/jv-2026-r4.pdf'));
  if n <> 2 then raise exception 'expected varsity r11 + jv r4, found %', n; end if;

  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 51 then raise exception 'varsity is %, PDF says 51', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 23 then raise exception 'jv is %, PDF says 23', n; end if;

  select count(*) into n from coaches where year = '2026-27' and name = 'Michael Hale';
  if n <> 1 then raise exception 'expected 1 Michael Hale, found %', n; end if;
end $$;

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r12.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r5.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;
update coaches set name = 'Jake Hale', updated_at = now()
 where year = '2026-27' and name = 'Michael Hale';

commit;

-- 230_varsity_roster_r7_galarza.sql
--
-- One name correction on the 2026-27 varsity roster, page AND print PDF.
-- From Jeremy 2026-10-06:
--
--   #90  Jesus Galaza -> Jesus Galarza  ("Galaza" came from the coaches' export
--        and was carried by 157)
--
-- PDF half, same sitting (176/186 rule): workbook cell F27 edited (r6 workbook
-- + PDF archived under roster_pdf/source/archive/), regenerated, diffed against
-- r6 (exactly that one line changed), uploaded as
-- documents/rosters/varsity-2026-r7.pdf (new filename per 158). r6 stays in the
-- bucket for the rollback.
--
-- DB-ONLY, NO DEPLOY. Rollback: 230_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and pl.jersey_number = '90' and pl.first_name = 'Jesus' and pl.last_name = 'Galaza';
  if n <> 1 then raise exception 'expected #90 Jesus Galaza, found % (already applied?)', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity'
     and pdf_storage_path = 'documents/rosters/varsity-2026-r6.pdf';
  if n <> 1 then raise exception 'varsity roster not on r6 (%)', n; end if;
end $$;

update players pl set last_name = 'Galarza', updated_at = now()
  from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '90' and pl.last_name = 'Galaza';

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r7.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity';

do $$
declare n int;
begin
  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and pl.last_name = 'Galaza';
  if n <> 0 then raise exception 'Galaza survived (%)', n; end if;

  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 49 then raise exception 'varsity roster is % rows, expected 49', n; end if;
end $$;

commit;

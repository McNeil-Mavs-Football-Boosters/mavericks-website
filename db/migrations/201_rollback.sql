-- 201_rollback.sql
--
-- Reverses 201: reinstates #15 Lucas Rosilmo DB Sr., removes Showels / Keller /
-- Conner / Kim from VARSITY ONLY (their JV and freshman rows were never 201's),
-- restores Jace Hicks to '64/65', re-densifies sort_order to 1..46, and points
-- Print View back at varsity-2026-r4.pdf, which is still in the bucket.
-- The workbook and r5 PDF are not touched by SQL; r4 is archived under
-- roster_pdf/source/archive/ if the printed roster has to go back too.

begin;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf';
  if rid is null then raise exception 'varsity roster is not on r5 (201 not applied?)'; end if;
  select count(*) into n from players where roster_id = rid;
  if n <> 49 then raise exception 'expected 49 varsity players, found %', n; end if;
end $$;

delete from players p
 using rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and (p.jersey_number, p.first_name, p.last_name) in
       (('15','Antonio','Showels'), ('24','TK','Keller'), ('37','Kevonn','Conner'), ('82','Henion','Kim'));

insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, '15', 'Lucas', 'Rosilmo', 'DB', 'Sr.', 0, true
  from rosters r
 where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null;

update players p
   set jersey_number = '64/65', updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '64' and p.first_name = 'Jace' and p.last_name = 'Hicks';

with ordered as (
  select p.id,
         row_number() over (order by split_part(p.jersey_number, '/', 1)::int) as rn
    from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
)
update players p
   set sort_order = o.rn, updated_at = now()
  from ordered o
 where o.id = p.id and p.sort_order is distinct from o.rn;

update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf',
       source_note = 'Varsity roster provided by the McNeil coaching staff, received 2026-08-24',
       updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null;
  select count(*) into n from players where roster_id = rid;
  if n <> 46 then raise exception 'expected 46 varsity players after rollback, found %', n; end if;
  if (select count(*) from players where roster_id = rid and jersey_number like '%/%') <> 4 then
    raise exception 'expected 4 slash jerseys after rollback'; end if;
end $$;

commit;

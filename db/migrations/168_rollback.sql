-- 168_rollback.sql — removes the 49 freshman players and unwires the Print View.
--
-- Leaves documents/rosters/freshman-2026.pdf in storage, same reasoning as
-- 166_rollback: storage is not transactional with the database, and an orphan
-- PDF costs nothing while a deleted one has to be re-sourced from the staff.
--
-- Scoped to the GREEN row. Blue was never seeded and must stay that way.
-- /roster/freshman/green returns to "Coming Soon" on its own; PrintViewLink
-- returns null on a null path so the button goes with it. No deploy either way.

begin;

delete from players p
 using rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'freshman'
   and r.team_designation = 'Green';

update rosters
set pdf_storage_path = null, source_note = null
where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green';

do $$
declare n int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='freshman';
  if n <> 0 then raise exception '% freshman players survived rollback', n; end if;

  select count(*) into n from rosters
   where year='2026-27' and team_level='freshman' and team_designation='Green'
     and pdf_storage_path is not null;
  if n <> 0 then raise exception 'freshman pdf_storage_path survived rollback'; end if;

  -- A freshman rollback must not touch the other two rosters.
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level in ('varsity','jv');
  if n <> 77 then raise exception 'varsity+JV lost players during rollback: %', n; end if;
end $$;

commit;

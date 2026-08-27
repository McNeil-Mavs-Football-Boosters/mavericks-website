-- 166_rollback.sql — removes the 32 JV players and unwires the Print View.
--
-- Leaves documents/rosters/jv-2026.pdf in storage. Same reasoning as
-- 164_rollback: storage is not transactional with the database, and an orphan
-- PDF costs nothing while a deleted one has to be re-sourced from the staff.
--
-- Restores the roster row to exactly its pre-166 state: no players, null
-- pdf_storage_path, null source_note. /roster/jv goes back to "Coming Soon"
-- on its own -- `PrintViewLink` returns null on a null path, so the button
-- disappears with it. No code change and no deploy either way.

begin;

delete from players p
 using rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'jv' and r.team_designation is null;

update rosters
set pdf_storage_path = null, source_note = null
where year = '2026-27' and team_level = 'jv' and team_designation is null;

do $$
declare n int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 0 then raise exception '% JV players survived rollback', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'jv' and pdf_storage_path is not null;
  if n <> 0 then raise exception 'JV pdf_storage_path survived rollback'; end if;

  -- Varsity must be untouched by a JV rollback.
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 45 then raise exception 'varsity lost players during JV rollback: %', n; end if;
end $$;

commit;

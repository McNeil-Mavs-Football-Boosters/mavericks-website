-- 191_rollback.sql
--
-- Puts the freshman Sep 10 kickoff back to 6:30, i.e. the school's April export.
-- ⚠️ That time is contradicted by Coach's own graphic, so roll this back only if
-- the graphic itself was wrong.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-10 18:00 America/Chicago';
  if n <> 1 then raise exception 'freshman Sep 10 is not 6:00 (not 191 to roll back?)'; end if;
end $$;

update games
   set game_date = timestamptz '2026-09-10 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-10 18:00 America/Chicago'
   and opponent = 'Rouse High School';

commit;

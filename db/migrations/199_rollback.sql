-- 199_rollback.sql
--
-- Puts the freshman Sep 17 kickoff back to 6:30, i.e. the school's April export.
-- ⚠️ That time is contradicted by Jeremy's 2026-09-17 relay; roll back only if
-- that relay was wrong.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-17 18:00 America/Chicago';
  if n <> 1 then raise exception 'freshman Sep 17 is not 6:00 (not 199 to roll back?)'; end if;
end $$;

update games
   set game_date = timestamptz '2026-09-17 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-17 18:00 America/Chicago'
   and opponent = 'Vista Ridge High School';

commit;

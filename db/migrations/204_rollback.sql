-- 204_rollback.sql
--
-- Reopens the varsity Sep 18 Vista Ridge row (final 28-56 -> scheduled, scores
-- cleared). Note this also puts the two Vista Ridge broadcast links back up.

begin;

update games
   set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-18 19:00 America/Chicago'
   and opponent = 'Vista Ridge High School'
   and result_status = 'final' and our_score = 28 and their_score = 56;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-18 19:00 America/Chicago' and result_status = 'scheduled';
  if n <> 1 then raise exception 'rollback did not take'; end if;
end $$;

commit;

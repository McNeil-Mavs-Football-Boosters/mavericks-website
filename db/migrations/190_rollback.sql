-- 190_rollback.sql
--
-- Returns the JV Sep 3 game to 'scheduled' with no score.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-03 19:00 America/Chicago'
     and result_status = 'final' and our_score = 0 and their_score = 51;
  if n <> 1 then raise exception 'JV Sep 3 is not 0-51 (not 190 to roll back?)'; end if;
end $$;

update games
   set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-03 19:00 America/Chicago'
   and opponent = 'Lake Belton High School';

commit;

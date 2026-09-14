-- 196_rollback.sql
--
-- Returns the varsity Rouse game (Fri 11 Sep) to 'scheduled' with no score.
-- ⚠️ This also republishes the VYPE and YouTube links, because keep_after_final
-- is evaluated against result_status. Only use it if the score was wrong.

begin;

update games
   set result_status = 'scheduled', our_score = null, their_score = null,
       updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
   and opponent = 'Rouse High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
     and result_status = 'scheduled' and our_score is null;
  if n <> 1 then raise exception 'rollback did not restore the scheduled state'; end if;
end $$;

commit;

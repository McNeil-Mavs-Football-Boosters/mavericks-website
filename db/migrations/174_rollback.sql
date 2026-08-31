-- 174_rollback.sql — returns the varsity Aug 28 game to 'scheduled', no score.

begin;

update games
set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
where year = '2026-27' and team_level = 'varsity'
  and game_date = timestamptz '2026-08-28 19:30 America/Chicago'
  and opponent = 'Austin Bowie High School';

commit;

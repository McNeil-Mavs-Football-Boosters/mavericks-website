-- 238_rollback.sql
begin;
update games set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-10-09 19:00 America/Chicago'
   and opponent = 'Stony Point High School';
commit;

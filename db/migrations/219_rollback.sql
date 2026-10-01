-- 219_rollback.sql -- JV Oct 1 back to 6:00 p.m.
begin;
update games
   set game_date = timestamptz '2026-10-01 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-10-01 17:30 America/Chicago'
   and opponent = 'Cedar Ridge High School';
commit;

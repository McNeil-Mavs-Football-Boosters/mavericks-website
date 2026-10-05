-- 225_rollback.sql -- freshman Green Oct 8 back to 6:30 p.m.
begin;
update games
   set game_date = timestamptz '2026-10-08 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-10-08 17:30 America/Chicago'
   and opponent = 'Stony Point High School';
commit;

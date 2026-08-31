-- 173_rollback.sql — returns Week 5 kickoffs to the school-PDF times:
-- JV Sep 3 back to 6:00 p.m., freshman Green Sep 3 back to 6:30 p.m.
-- The hidden freshman Blue row was never touched by 173 and stays at 5:00.

begin;

update games
   set game_date = timestamptz '2026-09-03 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-03 19:00 America/Chicago';

update games
   set game_date = timestamptz '2026-09-03 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-03 17:00 America/Chicago';

commit;

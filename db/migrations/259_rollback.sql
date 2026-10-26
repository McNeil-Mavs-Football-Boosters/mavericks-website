-- 259_rollback.sql
begin;
update games set game_date = timestamptz '2026-10-29 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and opponent = 'Westwood High School' and game_date = timestamptz '2026-10-29 17:30 America/Chicago';
update practice_schedules
   set body = replace(body,
     'See the Games schedule for the freshman game: Thursday Oct 29 vs Westwood at **5:30 p.m.** at Westwood Warrior Bowl (away).',
     'The freshman game Thursday Oct 29 vs Westwood is listed by Coach as **time and location TBA**. Check the Games schedule before Thursday.'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';
commit;

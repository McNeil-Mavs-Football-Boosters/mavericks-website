-- 259_freshman_westwood_530.sql
--
-- Freshman Westwood, Thu Oct 29: Coach announced 5:30 PM (Jeremy 2026-10-26,
-- "freshman game announced. 5:30 PM this week"). 257 left the Green row on the
-- seed 6:30 because Coach's Week 13 sheet said "time and location TBA".
-- Location: Jeremy gave a time only. The school's schedule PDF has this row as
-- AWAY at Westwood HS, which is what `games` already holds (Westwood Warrior
-- Bowl), so the venue is kept. Hidden Blue row untouched (225/237).
--
-- Freshman practice body: the "time and location TBA" closing line becomes the
-- confirmed kickoff. Day sections untouched.
--
-- DB-ONLY, NO DEPLOY. Rollback: 259_rollback.sql. Print View PDF goes to r8 in 260.

begin;

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'freshman' and g.team_designation = 'Green'
     and g.opponent = 'Westwood High School' and g.result_status = 'scheduled'
     and g.game_date = timestamptz '2026-10-29 18:30 America/Chicago' and v.name = 'Westwood Warrior Bowl';
  if n <> 1 then raise exception 'freshman Green Westwood not at seed 6:30 (%)', n; end if;
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%The freshman game Thursday Oct 29 vs Westwood is listed by Coach as **time and location TBA**. Check the Games schedule before Thursday.%';
  if n <> 1 then raise exception 'freshman body TBA line not found (%)', n; end if;
end $$;

update games set game_date = timestamptz '2026-10-29 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and opponent = 'Westwood High School' and game_date = timestamptz '2026-10-29 18:30 America/Chicago';

update practice_schedules
   set body = replace(body,
     'The freshman game Thursday Oct 29 vs Westwood is listed by Coach as **time and location TBA**. Check the Games schedule before Thursday.',
     'See the Games schedule for the freshman game: Thursday Oct 29 vs Westwood at **5:30 p.m.** at Westwood Warrior Bowl (away).'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and opponent = 'Westwood High School' and game_date = timestamptz '2026-10-29 17:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Green Westwood not 5:30 (%)', n; end if;
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%vs Westwood at **5:30 p.m.** at Westwood Warrior Bowl (away).%'
     and body not like '%TBA%';
  if n <> 1 then raise exception 'freshman body not as intended (%)', n; end if;
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Blue'
     and opponent = 'Westwood High School' and game_date = timestamptz '2026-10-29 17:00 America/Chicago';
  if n <> 1 then raise exception 'Blue row moved (%)', n; end if;
end $$;

commit;

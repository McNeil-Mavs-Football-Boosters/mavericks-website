-- 219_week9_jv_kickoff_530.sql
--
-- JV vs Cedar Ridge, Thu Oct 1, HOME at Maverick Stadium: kickoff 6:00 -> 5:30 p.m.
--
-- Source: Coach's MAV FOOTBALL WEEKLY SCHEDULE for Sep 28-Oct 2 (photo from
-- Jeremy 2026-09-28): "JV GAME / 5:30 p.m. Kickoff / McNeil High School".
-- `games` had 6:00 from the season seed. Coach's weekly doc outranks the seed
-- (120's rule), and earlier is the direction that strands a family.
--
-- Checked against the same doc and left alone: freshman Green at Cedar Ridge
-- 6:30 p.m. (matches), varsity at KRAC Fri Oct 2 7:00 p.m. (matches; Coach
-- writes "Kelley Reaves", venue row spelling kept). Hidden Blue row untouched.
-- /events and the ICS derive from `games`, so they follow.
--
-- DB-ONLY, NO DEPLOY. Rollback: 219_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-10-01 18:00 America/Chicago'
     and opponent = 'Cedar Ridge High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'JV Oct 1 not found at 6:00 (found %, already applied?)', n; end if;
end $$;

update games
   set game_date = timestamptz '2026-10-01 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-10-01 18:00 America/Chicago'
   and opponent = 'Cedar Ridge High School';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv'
     and g.game_date = timestamptz '2026-10-01 17:30 America/Chicago'
     and g.opponent = 'Cedar Ridge High School' and v.name = 'Maverick Stadium'
     and g.home_or_away = 'home';
  if n <> 1 then raise exception 'JV Oct 1 not at 5:30 home at Maverick Stadium (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-10-01 18:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Green Oct 1 6:30 disturbed'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-02 19:00 America/Chicago';
  if n <> 1 then raise exception 'varsity Oct 2 7:00 disturbed'; end if;
end $$;

commit;

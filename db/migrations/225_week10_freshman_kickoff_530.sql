-- 225_week10_freshman_kickoff_530.sql
--
-- Freshman Green vs Stony Point, Thu Oct 8, HOME at Maverick Stadium:
-- kickoff 6:30 -> 5:30 p.m.
--
-- Source: Coach's MAV FOOTBALL WEEKLY SCHEDULE for October 5-9 (photo from
-- Jeremy 2026-10-04): "FRESHMAN GAME / 5:30 p.m. at McNeil High School".
-- `games` had 6:30 from the season seed. Coach's weekly doc outranks the seed
-- (120/155), and earlier is the direction that strands a family.
--
-- Checked against the same doc and left alone: JV at Stony Point Thu Oct 8
-- 6:00 p.m. (matches), varsity Senior Night Fri Oct 9 7:00 p.m. at KRAC
-- (matches; Coach writes "Kelley Reaves", venue row spelling kept). Hidden Blue
-- row untouched (155/173/191/199). /events and the ICS derive from `games`.
--
-- The locker decorating event (215, Thu Oct 8 6-8 PM, "during and after the
-- freshman game") states no kickoff, so it needs no change and still reads true.
--
-- DB-ONLY, NO DEPLOY. Rollback: 225_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-10-08 18:30 America/Chicago'
     and opponent = 'Stony Point High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'freshman Green Oct 8 not found at 6:30 (found %, already applied?)', n; end if;
end $$;

update games
   set game_date = timestamptz '2026-10-08 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-10-08 18:30 America/Chicago'
   and opponent = 'Stony Point High School';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'freshman' and g.team_designation = 'Green'
     and g.game_date = timestamptz '2026-10-08 17:30 America/Chicago'
     and g.opponent = 'Stony Point High School' and v.name = 'Maverick Stadium'
     and g.home_or_away = 'home';
  if n <> 1 then raise exception 'freshman Oct 8 not at 5:30 home at Maverick Stadium (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-10-08 18:00 America/Chicago';
  if n <> 1 then raise exception 'JV Oct 8 6:00 disturbed'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-09 19:00 America/Chicago';
  if n <> 1 then raise exception 'varsity Oct 9 7:00 disturbed'; end if;
end $$;

commit;

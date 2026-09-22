-- 205_rollback.sql
--
-- Returns both Wednesday Sep 23 rows to the 203 state (tbd, JV at Lake Travis HS /
-- Cavalier Stadium, freshmen at 6:30), removes the Lake Travis Track Stadium venue,
-- and puts the "to be announced" wording back in the three practice bodies.

begin;

update games g
   set venue_id = v.id, location = 'Lake Travis HS', notes = null,
       result_status = 'tbd', updated_at = now()
  from venues v
 where v.name = 'Cavalier Stadium'
   and g.year = '2026-27' and g.team_level = 'jv'
   and g.game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and g.opponent = 'Lake Travis High School';

update games
   set game_date = timestamptz '2026-09-23 18:30 America/Chicago',
       result_status = 'tbd', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-23 17:30 America/Chicago'
   and opponent = 'Lake Travis High School';

delete from venues where name = 'Lake Travis Track Stadium'
  and not exists (select 1 from games where venue_id = venues.id);

update practice_schedules
   set body = replace(replace(body,
       'JV plays **Wednesday Sep 23 at 6:00 p.m.** at Lake Travis Track Stadium (not Cavalier Stadium) and varsity plays **Thursday Sep 24 at 7:00 p.m.** at Kelly Reeves. See the Games schedule.',
       'JV plays **Wednesday Sep 23** and varsity plays **Thursday Sep 24**. See the Games schedule for times and locations.'),
       'freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Lake Travis Track Stadium, varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.',
       'JV and freshmen Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
   set body = replace(replace(body,
       '(Sep 23), not Thursday. **Kickoff 5:30 p.m. at Maverick Stadium** (home). See the Games schedule.',
       '(Sep 23), not Thursday. Kickoff time to be announced — see the Games schedule.'),
       'freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Lake Travis Track Stadium, varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.',
       'freshmen and JV Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from games where year = '2026-27' and result_status = 'tbd';
  if n <> 2 then raise exception 'expected 2 tbd rows after rollback, found %', n; end if;
end $$;

commit;

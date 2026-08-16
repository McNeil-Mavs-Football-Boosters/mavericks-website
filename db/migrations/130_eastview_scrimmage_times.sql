-- 130_eastview_scrimmage_times.sql
--
-- The Thu Aug 20 Eastview scrimmage finally has times, from the same source as
-- migration 129: Coach's "MAV FOOTBALL WEEKLY SCHEDULE, August 17-23, 2026" doc.
--
-- Migration 078 seeded these four rows with `result_status = 'tbd'` because the
-- coaches' calendar had no time. The stored 6:00 PM was an explicit placeholder
-- and the games views render "TBD" in the time cell for tbd rows - so nothing
-- wrong was ever published, but the page has said TBD for a scrimmage that is
-- now four days out.
--
--   Upperclassmen (1st & 2nd group)  7:00 p.m.  -> varsity
--   Freshman & JV                    5:30 p.m.  -> jv, freshman Green + Blue
--
-- Identical split to the Aug 13 Hendrickson scrimmage 078 seeded as firm, and to
-- the JV reading taken in migrations 120 and 129. If that JV reading is ever
-- corrected, THIS ROW MOVES TOO - the practice bodies and the games rows have to
-- be changed together or a JV family gets two different scrimmage times off the
-- same site.
--
-- Location is left NULL, matching Hendrickson. The doc says "McNeil High School
-- Mavericks Stadium", which is what `home_or_away = 'home'` already conveys on
-- the games surfaces; the two other home rows carry no location string and
-- adding one only here would look like a different venue.

begin;

update games
   set game_date = '2026-08-20 19:00:00-05'::timestamptz,
       result_status = 'scheduled'
 where year = '2026-27' and opponent = 'Eastview High School'
   and team_level = 'varsity';

update games
   set game_date = '2026-08-20 17:30:00-05'::timestamptz,
       result_status = 'scheduled'
 where year = '2026-27' and opponent = 'Eastview High School'
   and (team_level = 'jv' or team_level = 'freshman');

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School';
  if n <> 4 then raise exception 'expected 4 Eastview rows, got %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and result_status = 'tbd';
  if n <> 0 then raise exception '% Eastview rows still tbd', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and game_date = '2026-08-20 19:00:00-05'::timestamptz;
  if n <> 1 then raise exception 'expected exactly 1 Eastview row at 7:00 PM, got %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and game_date = '2026-08-20 17:30:00-05'::timestamptz;
  if n <> 3 then raise exception 'expected 3 Eastview rows at 5:30 PM, got %', n; end if;
end $$;

commit;

-- /schedule/games/* reads at request time: live with no deploy.

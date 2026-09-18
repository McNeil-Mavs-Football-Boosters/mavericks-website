-- 203_week8_jv_freshman_tbd.sql
--
-- JV and freshman Green vs Lake Travis, WEDNESDAY Sep 23: kickoff times are not
-- yet announced, so both rows go to result_status = 'tbd'.
--
--   JV              Wed Sep 23  away  Lake Travis HS / Cavalier Stadium  6:00 <- school export, now TBD
--   Freshman Green  Wed Sep 23  home  Maverick Stadium                   6:30 <- school export, now TBD
--   Varsity         Thu Sep 24  home  KRAC                               7:00 <- matches Coach's doc, untouched
--
-- Source: Coach's MAV FOOTBALL WEEKLY SCHEDULE for Sep 21-25 writes "JV GAME /
-- Time TBA - Location TBA" and "FRESHMAN GAME / Time TBA - Location TBA", and
-- Jeremy 2026-09-18: "TBD on JV and freshman game times though."
--
-- ── WHY 'tbd' AND NOT LEAVING THE ROWS ALONE (181's choice) ──
-- 181 left the Week 6 Thursday rows at the school's times when Coach wrote TBA,
-- because 155's rule is that a kickoff MOVES only on Coach's graphic and TBA is
-- not a time. That rule is about moving to a different time. This is different:
-- Jeremy has said outright the times are not known, and the site has a status
-- built for exactly that (078/130): the games table and cards print "TBD" in
-- the time cell, and `lib/queries/game-events.ts` EXCLUDES tbd rows from the
-- events calendar and the ICS feed on purpose so a placeholder time is never
-- published as if it were real. The stored 6:00 / 6:30 stay in `game_date` as
-- the ordering placeholder, exactly as 078 did for the scrimmages.
--
-- ⚠️ THE COST: both games DROP OFF /events, the month view and the ICS until a
-- time is known. That is the designed behaviour and it is the right trade --
-- a calendar entry at 6:30 that turns out to be 5:00 strands a family (191's
-- lesson). When Coach gives the times, the fix is 130's shape: UPDATE game_date
-- AND set result_status back to 'scheduled' in one migration, per row.
--
-- ── LOCATIONS ARE NOT TOUCHED ──
-- Coach also writes "Location TBA". The rows carry the school's export: JV away
-- at Lake Travis (Cavalier Stadium), freshmen home at Maverick Stadium. Jeremy
-- said times only. A venue changes only on Coach's own graphic (155), and TBA is
-- not a venue. If a location comes in different, it is a one-row UPDATE.
--
-- ⚠️ THE HIDDEN BLUE ROW (5:00, Maverick Stadium) IS LEFT ALONE, same call as
-- 155/173/191/199: it renders nowhere and followups.md values it as the on-file
-- 5:00 record. The verify block asserts it is still 'scheduled' at 5:00.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/*, /events and the ICS read at request time.
--
-- Rollback: 203_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
     and opponent = 'Lake Travis High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'JV Sep 23 not found scheduled at 6:00 (found %, already applied?)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-23 18:30 America/Chicago'
     and opponent = 'Lake Travis High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'freshman Green Sep 23 not found scheduled at 6:30 (found %, already applied?)', n; end if;

  -- Varsity must already match Coach's doc, or this is the wrong week.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-24 19:00 America/Chicago'
     and location = 'KRAC' and result_status = 'scheduled';
  if n <> 1 then raise exception 'varsity Sep 24 is not 7:00 at KRAC as the doc says'; end if;
end $$;

update games
   set result_status = 'tbd', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and opponent = 'Lake Travis High School';

update games
   set result_status = 'tbd', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-23 18:30 America/Chicago'
   and opponent = 'Lake Travis High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and result_status = 'tbd';
  if n <> 2 then raise exception 'expected exactly 2 tbd rows in 2026-27, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and result_status = 'tbd'
     and game_date::date = date '2026-09-23'
     and ((team_level = 'jv' and location = 'Lake Travis HS')
       or (team_level = 'freshman' and team_designation = 'Green' and location = 'Maverick Stadium'));
  if n <> 2 then raise exception 'the tbd rows are not the two Wednesday Lake Travis rows'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Blue'
     and game_date = timestamptz '2026-09-23 17:00 America/Chicago' and result_status = 'scheduled';
  if n <> 1 then raise exception 'the hidden Blue Sep 23 row was disturbed'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-24 19:00 America/Chicago' and result_status = 'scheduled';
  if n <> 1 then raise exception 'varsity Sep 24 was disturbed'; end if;
end $$;

commit;

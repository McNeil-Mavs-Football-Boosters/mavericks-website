-- 199_week7_freshman_kickoff.sql
--
-- Freshman kickoff Thu 17 Sep at Vista Ridge: 6:30 p.m. -> 6:00 p.m.
-- From Jeremy 2026-09-17, the day of the game: "Freshman and JV games will both
-- be played at 6:00pm at the high schools."
--
--   Freshman  Thursday  Vista Ridge HS       6:00 PM   <- was 6:30, CHANGED
--   JV        Thursday  Maverick Stadium     6:00 PM   <- already 6:00, untouched
--   Varsity   Friday    Gupton Stadium       7:00 PM   <- untouched (198 has the links)
--
-- ⚠️ SOURCE IS JEREMY'S RELAY, NOT COACH'S GRAPHIC. 155's rule is that a
-- freshman kickoff moves only on Coach's own weekly graphic. Jeremy stated the
-- time directly and it is the day of the game, so his word is the source here;
-- if Coach's Week 7 graphic later disagrees, the graphic wins and this is a
-- one-row UPDATE.
--
-- "At the high schools" is not a venue change: JV's row is already home at
-- Maverick Stadium (5720 McNeil Drive, i.e. McNeil HS, per 155/191) and the
-- freshman row is already away at Vista Ridge Football Field (200 S Vista Ridge
-- Blvd). Varsity Friday is the separate Gupton Stadium row and is not touched.
--
-- 🚫 Third week running the freshman time has come in at something other than
-- the school's April export (5:00, 5:00, 6:00, now 6:00). Still per-week, still
-- per-game: DO NOT bulk-apply 6:00 to the remaining Green rows. The guard below
-- counts them at 6:30 and fails if any moved.
--
-- ⚠️ THE HIDDEN BLUE ROW IS LEFT AT 5:00, same call as 155/173/191: it renders
-- nowhere and followups.md values it as the on-file 5:00 record. A raw query
-- shows two freshman rows for Sep 17 at 5:00 and 6:00; only the 6:00 is real.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* and the ICS read at request time.
--
-- Rollback: 199_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-17 18:30 America/Chicago'
     and opponent = 'Vista Ridge High School';
  if n <> 1 then
    raise exception 'freshman Green Sep 17 not found at 6:30 (found %, already applied?)', n;
  end if;

  -- JV and varsity must already match what Jeremy described, or this migration
  -- is looking at a different week than the one in front of it.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-17 18:00 America/Chicago'
     and location = 'Maverick Stadium';
  if n <> 1 then raise exception 'JV Sep 17 is not 6:00 at Maverick Stadium'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-18 19:00 America/Chicago'
     and location = 'Gupton';
  if n <> 1 then raise exception 'varsity Sep 18 is not 7:00 at Gupton'; end if;
end $$;

update games
   set game_date = timestamptz '2026-09-17 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-17 18:30 America/Chicago'
   and opponent = 'Vista Ridge High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-17 18:00 America/Chicago';
  if n <> 1 then raise exception 'freshman kickoff did not move to 6:00'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Blue'
     and game_date = timestamptz '2026-09-17 17:00 America/Chicago';
  if n <> 1 then raise exception 'the hidden Blue Sep 17 row was disturbed'; end if;

  -- 🚫 Remaining Green rows must NOT have been bulk-moved. 191 counted SEVEN
  -- (Sep 17 onward); moving Sep 17 makes it SIX: Sep 23, Oct 1, 8, 15, 22, 29.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date > timestamptz '2026-09-18 00:00 America/Chicago'
     and extract(hour from game_date at time zone 'America/Chicago') = 18
     and extract(minute from game_date at time zone 'America/Chicago') = 30;
  if n <> 6 then
    raise exception 'expected 6 later Green rows still at 6:30, found % -- did something bulk-apply?', n;
  end if;
end $$;

commit;

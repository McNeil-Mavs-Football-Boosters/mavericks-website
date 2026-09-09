-- 191_week6_freshman_kickoff.sql
--
-- Freshman kickoff Thu 10 Sep at Rouse: 6:30 p.m. -> 6:00 p.m.
-- From Coach's "THIS WEEK'S GAMES" graphic, sent by Jeremy 2026-09-08.
--
--   Freshman  Thursday  Rouse High School   6:00 PM   <- was 6:30, CHANGED
--   JV        Thursday  McNeil High School  6:00 PM   <- already 6:00, untouched
--   Varsity   Friday    Gupton Stadium      7:00 PM   <- already 7:00, untouched
--
-- 181 published both Thursday kickoffs with an explicit "not yet confirmed"
-- hedge because Coach's WEEKLY SCHEDULE said "JV GAME - TBA" and "FRESHMAN GAME
-- - TBA" while `games` still carried the school's April export. This graphic is
-- the confirmation. JV's 6:00 was right; the freshman 6:30 was not.
--
-- ── 🚨 6:00 IS A THIRD DISTINCT TIME AND IT MATCHES NEITHER HALF OF THE
-- SCHOOL'S STAGGER. That footnote is "Blue @ 5:00 / Green @ 6:30", a TWO-team
-- arrangement McNeil does not run (148). 155 and 173 both resolved a freshman
-- time by moving Green onto the 5:00 Blue slot, and after two weeks at 5:00 it
-- looked like the season shape. **It is not.** Jeremy 2026-08-25: the slot
-- "could shift week to week because they don't have a green and blue team. 1
-- team means they could play early or late depending on the school opponent."
-- This is that, demonstrated: 5:00, 5:00, now 6:00.
-- 🚫 So the standing rule holds harder than before: DO NOT bulk-apply a freshman
-- kickoff to the remaining rows, and do not infer one from the stagger. Each
-- week's time comes from Coach's own graphic, verified per game.
--
-- ── ⚠️ THE HIDDEN BLUE ROW IS LEFT AT 5:00, AND THAT IS A JUDGEMENT CALL ──
-- 170's rule says a freshman change touches BOTH rows, or `games` asserts
-- something the site does not show. That rule was about a CANCELLATION, where
-- leaving Blue claims a game that never happened. This is a time, on a row that
-- renders nowhere (`freshman_has_blue = false`, both Blue routes 404, and
-- `getGamesAsEvents` filters it out of /events, the month view and the ICS).
-- Weighed against it, `followups.md` explicitly values these rows as "the on-file
-- record of the 5:00 timing", and 155 and 173 both left Blue alone on a time
-- change. So it stays.
-- ⚠️ The cost is real and is stated here rather than hidden: a raw query on
-- `games` now shows two freshman rows for Sep 10, at 5:00 and 6:00, and only the
-- 6:00 is a real game. If that ever becomes load-bearing, move Blue and say so.
--
-- ── 🚨 THE 9/7 NEWSLETTER WENT OUT SAYING 6:30 AND IS NOW WRONG ──
-- It hedged ("treat those as likely and not final") and pointed at the schedule
-- page, which is why the hedge was there. But the correction moves kickoff
-- THIRTY MINUTES EARLIER, so a family working from the email arrives late --
-- the one direction of error that actually strands somebody. Same class as the
-- Dragon Stadium / KRAC mistake in the 8/31 issue, which needed a correction
-- rather than a silent regeneration. Flagged to Jeremy 2026-09-08.
--
-- Venue and home/away are NOT touched: the graphic's "ROUSE HIGH SCHOOL" is the
-- row's existing 'Rouse HS' away, and its "MCNEIL HIGH SCHOOL" for JV is what
-- this club's rows call 'Maverick Stadium' -- 155 settled that naming and the
-- graphic using the school's name is not a venue change.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* and the ICS read at request time.
--
-- Rollback: 191_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-10 18:30 America/Chicago'
     and opponent = 'Rouse High School';
  if n <> 1 then
    raise exception 'freshman Green Sep 10 not found at 6:30 (found %, already applied?)', n;
  end if;

  -- JV and varsity must already match the graphic, or this migration is looking
  -- at a different week than the one in front of it.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-10 18:00 America/Chicago';
  if n <> 1 then raise exception 'JV Sep 10 is not 6:00 as the graphic says'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
     and location = 'Gupton';
  if n <> 1 then raise exception 'varsity Sep 11 is not 7:00 at Gupton as the graphic says'; end if;
end $$;

update games
   set game_date = timestamptz '2026-09-10 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-10 18:30 America/Chicago'
   and opponent = 'Rouse High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-10 18:00 America/Chicago';
  if n <> 1 then raise exception 'freshman kickoff did not move to 6:00'; end if;

  -- Nothing else moved. Exactly one Green row on Sep 10, and the Blue row is
  -- still where this migration deliberately left it.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Blue'
     and game_date = timestamptz '2026-09-10 17:00 America/Chicago';
  if n <> 1 then raise exception 'the hidden Blue Sep 10 row was disturbed'; end if;

  -- 🚫 The remaining Green rows must NOT have been bulk-moved. There are SEVEN:
  -- Sep 17, Sep 23, Oct 1, Oct 8, Oct 15, Oct 22, Oct 29.
  --
  -- ⚠️ A first draft of this guard expected EIGHT and correctly failed. That
  -- number came from 173's note that "the remaining eight Green rows still say
  -- 6:30" -- true when 173 was written, because Sep 10 was still one of them.
  -- Moving Sep 10 is what this migration does, so the set is one smaller.
  -- **The stale number was in the comment, not the data.** Verified against the
  -- rows before changing it. If a later migration moves another one, this drops
  -- to six; do not "fix" a failure here by loosening the check.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date > timestamptz '2026-09-11 00:00 America/Chicago'
     and extract(hour from game_date at time zone 'America/Chicago') = 18
     and extract(minute from game_date at time zone 'America/Chicago') = 30;
  if n <> 7 then
    raise exception 'expected 7 later Green rows still at 6:30, found % -- did something bulk-apply?', n;
  end if;
end $$;

commit;

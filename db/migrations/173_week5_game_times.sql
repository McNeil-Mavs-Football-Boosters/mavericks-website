-- 173_week5_game_times.sql
--
-- Week 5 kickoff times, from Coach's MAV FOOTBALL WEEKLY SCHEDULE for
-- August 31-September 6 2026 (Jeremy sent the doc 2026-08-31). Coach lists:
--
--     JV GAME       - 7:00 p.m. - Lake Belton High School
--     FRESHMAN GAME - 5:00 p.m. - McNeil High School
--     VARSITY GAME  - 7:00 p.m. - Dragon Stadium
--
-- Split from 172 (the practice bodies) on purpose: same source doc, but a
-- kickoff time is what a family plans a Thursday evening around, and it should
-- roll back on its own. 153/155 split the same way for the same reason.
--
-- ── WHAT CHANGES, AND WHY IT IS NOT A GUESS ──
--
-- 1. JV Thu Sep 3: 6:00 p.m. -> 7:00 p.m. The 6:00 came from the school's
--    season PDF, which lists 6:00 for every JV game. 155 already established
--    that when Coach's weekly doc and the school's PDF disagree about THIS
--    week, the weekly doc wins (it did varsity 7:00 -> 7:30 for Aug 28 on
--    exactly that basis). Venue and home/away already match Coach's doc -- away
--    at Lake Belton High School -- so only the time moves.
--
-- 2. Freshman Thu Sep 3, GREEN row: 6:30 p.m. -> 5:00 p.m. This is 155's Aug 27
--    change repeated for the next date, and 155 said in as many words that it
--    would need repeating: "Later weeks keep 6:30 until Coach publishes
--    otherwise - this is a WEEK-SPECIFIC change, not a season rule." Coach has
--    now published otherwise. The school's footnote is "Blue @ 5:00 / Green @
--    6:30", which is a TWO-TEAM stagger; McNeil fields ONE freshman team
--    (migration 148), so the surviving team plays the 5:00 slot and the 6:30 on
--    the Green row is the stale half of a pair.
--    The hidden Blue row is ALREADY 5:00 and is deliberately left alone, so both
--    freshman rows read 5:00 for this date -- same end state 155 produced for
--    Aug 27, and correct for a single team.
--
-- 3. Varsity Fri Sep 4 is 7:00 p.m. in both the DB and Coach's doc, and the
--    venue already reads Round Rock High School Dragon Stadium. NOT TOUCHED.
--    Stated here because its absence from this migration is a finding, not an
--    oversight: last week needed a varsity time fix and this week does not.
--
-- ⚠️ THE REMAINING EIGHT GREEN ROWS (Sep 10 -> Oct 29) STILL SAY 6:30, and the
-- remaining eight JV rows still say 6:00. Two consecutive weeks have now come in
-- at freshman 5:00, so this looks like the season shape rather than a per-week
-- accident -- but "looks like" is not Coach saying so, and 155's rule stands
-- until it does. Flagged for Jeremy 2026-08-31; do not bulk-flip them on the
-- strength of this migration alone. Whoever gets Coach's confirmation should do
-- it in one migration and delete this paragraph.
--
-- Times are America/Chicago literals; Sep 2026 is CDT (UTC-5).
--
-- DB-ONLY, NO DEPLOY. /schedule/games/*, /events, the month view and the ICS
-- feed all read at request time.
--
-- Rollback: 173_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-03 18:00 America/Chicago';
  if n <> 1 then raise exception 'JV Sep 3 not at 6:00 p.m. as expected (found %)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-03 18:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Green Sep 3 not at 6:30 p.m. (found %)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-04 19:00 America/Chicago';
  if n <> 1 then raise exception 'varsity Sep 4 no longer 7:00 p.m. (found %)', n; end if;
end $$;

update games
   set game_date = timestamptz '2026-09-03 19:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-03 18:00 America/Chicago';

update games
   set game_date = timestamptz '2026-09-03 17:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-03 18:30 America/Chicago';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-03 19:00 America/Chicago';
  if n <> 1 then raise exception 'JV Sep 3 did not move to 7:00 p.m.'; end if;

  -- Both freshman rows on this date must now read 5:00.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman'
     and game_date = timestamptz '2026-09-03 17:00 America/Chicago';
  if n <> 2 then raise exception 'expected 2 freshman rows at 5:00 p.m. Sep 3, found %', n; end if;

  -- Nothing outside Sep 3 may have moved. ⚠️ The date must be taken in
  -- America/Chicago: `game_date::date` resolves in the SESSION timezone, and
  -- under UTC a 7:00 p.m. CDT kickoff falls on the NEXT calendar day, so this
  -- guard counted the row it had just correctly updated. Cost one failed run.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and (game_date AT TIME ZONE 'America/Chicago')::date <> date '2026-09-03'
     and (game_date AT TIME ZONE 'America/Chicago')::time = time '19:00';
  if n <> 0 then raise exception '% other JV rows now read 7:00 p.m.', n; end if;
end $$;

commit;

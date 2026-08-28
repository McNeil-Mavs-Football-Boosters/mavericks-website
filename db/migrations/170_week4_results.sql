-- 170_week4_results.sql
--
-- Week 4 results, Thu 27 Aug 2026. Jeremy 2026-08-28.
--
--   JV vs Austin Bowie ............ LOST 6-34 (final)
--   Freshman vs Austin Bowie ...... CANCELLED, lightning
--
-- ⚠️ SCORE ORDER: our_score FIRST. Jeremy reported it as "JV lost 34-6", which
-- is the conventional winner-first phrasing. In this table the columns are
-- explicitly ours/theirs, so that is our_score = 6, their_score = 34.
-- `ResultCell` renders "L 6-34" (ours first, always), which is deliberate and
-- consistent with every other row -- do not "fix" it to read 34-6.
--
-- ⚠️ BOTH FRESHMAN ROWS ARE CANCELLED, INCLUDING THE HIDDEN BLUE ONE. Migration
-- 148 set `freshman_has_blue = false`, so the Blue row is invisible on every
-- surface, but it still exists in `games`. Migration 155 established the rule
-- when it moved both Aug 27 freshman rows to the Burger Annex: updating only the
-- visible Green row leaves a row in the table asserting something untrue, and a
-- raw query then disagrees with the site. Same reasoning here.
--
-- ── WHAT THIS ALSO DOES, WITHOUT ANY EXTRA WORK ──
-- `CALENDAR_STATUSES` in lib/queries/game-events.ts is ["scheduled", "final"],
-- so a cancelled game drops out of /events, the month view and the ICS feed on
-- its own. That is the designed behaviour, not a side effect to work around.
-- Subscribed calendars simply lose the entry rather than showing it struck
-- through; the game is in the past, so nobody is misled.
-- `TicketCell` and the broadcast links also hide once a game is concluded, which
-- covers both of these.
--
-- The JV game had no broadcast rows (VYPE covers varsity only), so nothing in
-- game_broadcasts is affected. The varsity game is Fri 28 Aug and is untouched
-- here -- its result is a separate, later migration.
--
-- DB-ONLY, NO DEPLOY.

begin;

update games
set result_status = 'final', our_score = 6, their_score = 34
where year = '2026-27' and team_level = 'jv' and team_designation is null
  and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
  and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
  and opponent = 'Austin Bowie High School';

update games
set result_status = 'cancelled'
where year = '2026-27' and team_level = 'freshman'
  and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
  and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
  and opponent = 'Austin Bowie High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year='2026-27' and team_level='jv' and team_designation is null
     and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
     and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
     and result_status = 'final' and our_score = 6 and their_score = 34;
  if n <> 1 then raise exception 'JV result not recorded as expected (% rows)', n; end if;

  -- Both freshman rows, Green and the hidden Blue.
  select count(*) into n from games
   where year='2026-27' and team_level='freshman'
     and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
     and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
     and result_status = 'cancelled';
  if n <> 2 then
    raise exception 'expected 2 cancelled freshman rows (Green + hidden Blue), found %', n;
  end if;

  -- A cancelled game must never carry a score.
  select count(*) into n from games
   where year='2026-27' and result_status='cancelled'
     and (our_score is not null or their_score is not null);
  if n <> 0 then raise exception '% cancelled games have a score', n; end if;

  -- Nothing else in the season moved off 'scheduled'.
  select count(*) into n from games
   where year='2026-27' and result_status not in ('scheduled','final','cancelled');
  if n <> 0 then raise exception '% games ended up in an unexpected status', n; end if;

  select count(*) into n from games where year='2026-27' and result_status='final';
  if n <> 1 then raise exception 'expected exactly 1 final game so far, found %', n; end if;
end $$;

commit;

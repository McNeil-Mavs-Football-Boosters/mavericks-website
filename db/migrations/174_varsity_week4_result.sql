-- 174_varsity_week4_result.sql
--
-- Varsity season opener, Fri 28 Aug 2026 at Austin Bowie (Burger Stadium):
--
--   Varsity at Austin Bowie ....... LOST 14-62 (final)
--
-- Jeremy 2026-08-31: "62 (bowie) to 14 (mcneil)... it was uglier than the score
-- even."
--
-- ⚠️ SCORE ORDER: our_score FIRST, same as 170. Reported winner-first as 62-14;
-- the columns here are explicitly ours/theirs, so our_score = 14,
-- their_score = 62. `ResultCell` renders "L 14-62". Do not "fix" it to 62-14.
--
-- ── THIS FINALLY EXERCISES THE POST-FINAL BROADCAST RENDER ──
-- followups.md has carried an open item since migration 165: nothing had ever
-- been observed transitioning to `final` WITH broadcast rows attached. The only
-- prior final was JV Aug 27, which has none (VYPE covers varsity only). This
-- game has both rows, and they are designed to behave DIFFERENTLY:
--
--   YouTube  keep_after_final = true   -> persists, it becomes the replay
--   VYPE     keep_after_final = false  -> disappears, the per-game vendor page rots
--
-- No data change is needed for either; the flip to `final` is what drives it.
-- Verify on /schedule/games/varsity after applying, and close that followup.
--
-- This was three days late. The game was Friday and the site still said
-- "scheduled" on Monday morning, which is the one state that actively misleads:
-- a scheduled past game reads as a game still to come, and it kept the row in
-- /events, the month view and the ICS feed. Nothing prompts a result to be
-- entered -- 170 recorded Thursday's JV loss the next day and simply did not
-- cover Friday's varsity game. **If a weekly newsletter is being written, that
-- is the moment to check every past game has a result**, because the newsletter
-- needs the score anyway.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 174_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-08-28 19:30 America/Chicago'
     and opponent = 'Austin Bowie High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Aug 28 vs Bowie not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 14, their_score = 62, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-08-28 19:30 America/Chicago'
   and opponent = 'Austin Bowie High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-08-28 19:30 America/Chicago'
     and result_status = 'final' and our_score = 14 and their_score = 62;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  -- No REGULAR-SEASON game in the past may still read 'scheduled'. This is the
  -- check whose absence let Friday sit wrong for three days.
  --
  -- ⚠️ SCOPED TO AUG 24 ONWARD ON PURPOSE, AND THE REASON IS A REAL FINDING.
  -- An unscoped version of this guard failed on 8 rows: the Aug 13 Hendrickson
  -- and Aug 20 Eastview SCRIMMAGES (varsity, JV and both freshman rows each),
  -- every one still 'scheduled' weeks after being played. That is pre-existing
  -- and NOT fixed here, because 'final' with no score is a claim about a
  -- scrimmage nobody kept an official score for, and this migration is not the
  -- place to invent a convention for them. They still sit in `CALENDAR_STATUSES`
  -- and so still appear in /events, the month view and the ICS feed as though
  -- they were upcoming. Flagged for Jeremy 2026-08-31; needs a decision on what
  -- a played scrimmage should read, then one migration for all eight.
  select count(*) into n from games
   where year = '2026-27' and result_status = 'scheduled'
     and game_date < now()
     and game_date >= timestamptz '2026-08-24 00:00 America/Chicago';
  if n <> 0 then
    raise exception '% past regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

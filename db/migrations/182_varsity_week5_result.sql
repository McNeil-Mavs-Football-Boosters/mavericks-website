-- 182_varsity_week5_result.sql
--
-- Game 2, Fri 4 Sep 2026 vs Lake Belton at Kelly Reeves (KRAC), the varsity home
-- opener that 177 moved off Dragon Stadium three days out:
--
--   Varsity vs Lake Belton ....... LOST 24-30 (final)
--
-- Jeremy 2026-09-06: "McNeil varsity lost heartbreaker last week 30-24 (was a
-- great hard fought game)".
--
-- ⚠️ SCORE ORDER: our_score FIRST, same as 170 and 174. Reported winner-first as
-- 30-24; the columns are explicitly ours/theirs, so our_score = 24,
-- their_score = 30, and `ResultCell` renders "L 24-30". Do not "fix" it.
--
-- ── THE BROADCAST ROWS NEED NO CHANGE, AND THAT IS 180 WORKING ──
-- Both Sep 4 rows (YouTube + VYPE) were inserted with keep_after_final = false,
-- because 180 retired 165's theory that a YouTube link survives as a replay --
-- Bowie's coach had last week's pulled. Marking the game final is what drops
-- them; no data change here. Verify on /schedule/games/varsity that neither link
-- renders after this applies.
--
-- ⚠️ THE THURSDAY SEP 3 GAMES ARE STILL 'scheduled' AND THIS MIGRATION DOES NOT
-- TOUCH THEM. JV vs Lake Belton and both freshman rows (Green and Blue) were
-- played on Sep 3 and no result was supplied. Guessing one is worse than the
-- 'scheduled' state, so the post-hoc guard 174 introduced is scoped past them
-- rather than deleted. Asked of Jeremy 2026-09-06; they need their own
-- migration, and per 170 the hidden Blue row gets the same treatment as Green.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 182_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and opponent = 'Lake Belton High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Sep 4 vs Lake Belton not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 24, their_score = 30, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-04 19:00 America/Chicago'
   and opponent = 'Lake Belton High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and result_status = 'final' and our_score = 24 and their_score = 30;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  -- Both Sep 4 broadcast rows must be keep_after_final = false, or the links
  -- will persist on a concluded game -- the exact thing 180 was written to stop.
  select count(*) into n from game_broadcasts b
    join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and b.keep_after_final;
  if n <> 0 then raise exception '% Sep 4 broadcast row(s) would survive the final', n; end if;

  -- No past varsity REGULAR-SEASON game may still read 'scheduled'.
  --
  -- ⚠️ TWO EXCLUSIONS, BOTH LOAD-BEARING, BOTH FOUND BY THIS GUARD FIRING.
  --
  -- SCOPED TO VARSITY because the three Sep 3 rows (JV + both freshman) were
  -- played and no result was supplied, and guessing is worse than 'scheduled'.
  --
  -- SCRIMMAGES EXCLUDED because a first draft of this guard failed on the
  -- varsity Aug 13 Hendrickson and Aug 20 Eastview rows -- exactly the eight
  -- rows (four levels x two dates) that 174 documented as still 'scheduled'
  -- weeks after being played and deliberately did not fix. 174 excluded them by
  -- date; this uses `notes <> 'Scrimmage'`, which is the clean selector 176
  -- found (`notes` carries exactly three values in 2026-27: 'Scrimmage',
  -- 'Senior Night', 'Homecoming'). A date scope silently stops protecting
  -- anything once the season moves past it; this one keeps working all year.
  --
  -- 🚫 Excluding them is NOT resolving them. All eight still show in /events,
  -- the month view and the ICS feed as though they are upcoming, and still need
  -- a decision on what a played scrimmage should read. See followups.md.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past varsity regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

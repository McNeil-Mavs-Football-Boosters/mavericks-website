-- 190_jv_week5_result.sql
--
-- JV, Thu 3 Sep 2026 away at Lake Belton:
--
--   JV at Lake Belton ....... LOST 0-51 (final)
--
-- Jeremy 2026-09-07: "JV lost 0-51". Four days late, which 174 already flagged
-- as the recurring failure: nothing prompts a non-varsity result to be entered.
--
-- ⚠️ SCORE ORDER: our_score FIRST, per 170/174/182. Reported the conventional
-- way and stored 0 / 51, so `ResultCell` renders "L 0-51".
--
-- ── 🚨 THIS IS THE SEASON'S FIRST ZERO, AND A ZERO IS THE SCORE MOST LIKELY TO
-- BE SILENTLY DROPPED BY CODE. `0` is falsy in JS, so any `if (our_score)` or
-- `our_score ||` would treat a shutout as "no result" and render an em-dash --
-- a game we lost 0-51 would look like a game nobody had entered. Checked before
-- applying: `result-cell.tsx` is the ONLY reader of these columns and it tests
-- `our_score == null`, which is correct. **Keep it that way.** This is the same
-- class of trap as jersey number 0 (Tyson Cox), where `if (!value)` would have
-- dropped a real player -- see `cell_text` in make-varsity-roster-pdf.py.
--
-- ⚠️ THE TWO FRESHMAN Sep 3 ROWS ARE DELIBERATELY NOT TOUCHED. Jeremy is still
-- chasing that score. Guessing is worse than the wrong state, so the post-hoc
-- guard below stays scoped away from them, exactly as 182's was. When it lands,
-- **both** freshman rows get it, Green and the hidden Blue, per 170's rule --
-- otherwise a raw query asserts a game the site does not show.
--
-- 🚫 Still unresolved and NOT this migration's business: the eight August
-- scrimmage rows that remain 'scheduled' weeks after being played (174).
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 190_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-03 19:00 America/Chicago'
     and opponent = 'Lake Belton High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'JV Sep 3 vs Lake Belton not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 0, their_score = 51, updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-03 19:00 America/Chicago'
   and opponent = 'Lake Belton High School';

do $$
declare n int;
begin
  -- Assert the zero survived as a zero and not as NULL.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-03 19:00 America/Chicago'
     and result_status = 'final' and our_score = 0 and their_score = 51
     and our_score is not null;
  if n <> 1 then raise exception 'JV result did not take as 0-51'; end if;

  -- No past JV or VARSITY regular-season game may still read 'scheduled'.
  -- ⚠️ FRESHMAN IS EXCLUDED ON PURPOSE (Sep 3 score still outstanding) and
  -- scrimmages are excluded per 182's `notes` selector. Widen this the moment
  -- the freshman rows are filled in.
  select count(*) into n from games
   where year = '2026-27' and team_level in ('jv','varsity')
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past jv/varsity regular-season game(s) still scheduled', n;
  end if;
end $$;

commit;

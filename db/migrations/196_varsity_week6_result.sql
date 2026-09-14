-- 196_varsity_week6_result.sql
--
-- Game 3, Fri 11 Sep 2026 at Rouse (Gupton Stadium):
--
--   Varsity at Rouse ............. LOST 3-55 (final)
--
-- Jeremy 2026-09-14: "varsity lost 55-3 last week."
--
-- ⚠️ SCORE ORDER: our_score FIRST, same as 170, 174 and 182. Reported
-- winner-first as 55-3; the columns are explicitly ours/theirs, so our_score = 3
-- and their_score = 55, and `ResultCell` renders "L 3-55". Do not "fix" it.
--
-- ── THIS IS WHAT TAKES THE BROADCAST LINKS DOWN ──
-- 195 inserted the Rouse VYPE and YouTube rows with keep_after_final = false,
-- per 180. Those links have therefore been live on /schedule/games/varsity for
-- three days on a game that was over, because **`keep_after_final` only fires
-- once a game is marked `final`** and nobody had entered the result. 174 and 180
-- both flagged that dependency in the abstract; this is the first time it
-- actually cost anything. 🚨 **The result IS the takedown mechanism.** If a
-- future week's links need to come down and the score is not to hand, deactivate
-- the rows explicitly rather than waiting on the result.
--
-- ⚠️ THE THURSDAY SEP 10 GAMES ARE STILL 'scheduled' AND THIS DOES NOT TOUCH
-- THEM. JV vs Rouse and both freshman rows played Sep 10 and no result was
-- supplied. Guessing is worse than 'scheduled' -- same call as 182 made for the
-- Sep 3 rows, which are ALSO still open. That is now two weeks of sub-varsity
-- results outstanding (Sep 3 and Sep 10) plus the eight scrimmage rows. The
-- post-hoc guard below stays scoped to varsity for exactly that reason.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 196_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
     and opponent = 'Rouse High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Sep 11 at Rouse not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 3, their_score = 55, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
   and opponent = 'Rouse High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-11 19:00 America/Chicago'
     and result_status = 'final' and our_score = 3 and their_score = 55;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  -- Neither Rouse broadcast row may outlive the final whistle. 195 set both to
  -- false; this asserts it at the moment it starts to matter.
  select count(*) into n from game_broadcasts b
    join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-11 19:00 America/Chicago'
     and b.keep_after_final;
  if n <> 0 then raise exception '% Rouse broadcast row(s) would survive the final', n; end if;

  -- No past varsity REGULAR-SEASON game may still read 'scheduled'. Scoped to
  -- varsity and excluding scrimmages, for the reasons 182 documents at length.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past varsity regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

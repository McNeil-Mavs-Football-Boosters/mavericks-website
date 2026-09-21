-- 204_varsity_week7_result.sql
--
-- Game 4, Fri 18 Sep 2026 at Vista Ridge (Gupton Stadium):
--
--   Varsity at Vista Ridge ....... LOST 28-56 (final)
--
-- Jeremy 2026-09-20: "varsity lost on friday to vista ridge 28-56."
--
-- ⚠️ SCORE ORDER: our_score FIRST, same as 170/174/182/196. Jeremy reported it
-- ours-first this time (28-56), so our_score = 28, their_score = 56, and
-- `ResultCell` renders "L 28-56".
--
-- ── THIS IS WHAT TAKES THE BROADCAST LINKS DOWN (196's lesson) ──
-- 198 inserted the Vista Ridge VYPE and YouTube rows with keep_after_final =
-- false. They have been live on /schedule/games/varsity for two days on a game
-- that was over, because `keep_after_final` only fires once the game is `final`.
-- Marking the game final IS the takedown. The verify block asserts neither row
-- would survive.
--
-- ⚠️ THE THURSDAY SEP 17 GAMES ARE STILL 'scheduled' AND THIS DOES NOT TOUCH
-- THEM. JV vs Vista Ridge and the freshman rows played Sep 17 and no result was
-- supplied. Guessing is worse than 'scheduled' (182/196). That is now THREE weeks
-- of sub-varsity results outstanding (Sep 3, Sep 10, Sep 17). The post-hoc guard
-- stays scoped to varsity.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 204_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-18 19:00 America/Chicago'
     and opponent = 'Vista Ridge High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Sep 18 at Vista Ridge not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 28, their_score = 56, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-18 19:00 America/Chicago'
   and opponent = 'Vista Ridge High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-18 19:00 America/Chicago'
     and result_status = 'final' and our_score = 28 and their_score = 56;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  select count(*) into n from game_broadcasts b
    join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-18 19:00 America/Chicago'
     and b.keep_after_final;
  if n <> 0 then raise exception '% Vista Ridge broadcast row(s) would survive the final', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past varsity regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

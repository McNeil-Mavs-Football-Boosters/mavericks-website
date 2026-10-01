-- 217_varsity_week8_result.sql
--
-- Game 5, Thu 24 Sep 2026, HOME vs Lake Travis (KRAC):
--
--   Varsity vs Lake Travis ....... LOST 6-59 (final)
--
-- Jeremy 2026-09-25: "mcneil lost last night 6-59 (varsity)".
--
-- ⚠️ SCORE ORDER: our_score FIRST, same as 170/174/182/196/204. Jeremy reported
-- it ours-first (6-59), so our_score = 6, their_score = 59, and `ResultCell`
-- renders "L 6-59".
--
-- ── THIS IS WHAT TAKES THE BROADCAST LINKS DOWN (196's lesson) ──
-- 216 inserted the Lake Travis VYPE and YouTube rows with keep_after_final =
-- false. Marking the game final IS the takedown. The verify block asserts
-- neither row would survive.
--
-- ⚠️ THE WEDNESDAY SEP 23 JV AND FRESHMAN GAMES ARE STILL 'scheduled' AND THIS
-- DOES NOT TOUCH THEM. No result was supplied. Four weeks of sub-varsity results
-- now outstanding (Sep 3, 10, 17, 23). The post-hoc guard stays scoped to varsity.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
--
-- Rollback: 217_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-24 19:00 America/Chicago'
     and opponent = 'Lake Travis High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Sep 24 vs Lake Travis not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 6, their_score = 59, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-24 19:00 America/Chicago'
   and opponent = 'Lake Travis High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-24 19:00 America/Chicago'
     and result_status = 'final' and our_score = 6 and their_score = 59;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  select count(*) into n from game_broadcasts b
    join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-24 19:00 America/Chicago'
     and b.keep_after_final;
  if n <> 0 then raise exception '% Lake Travis broadcast row(s) would survive the final', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past varsity regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

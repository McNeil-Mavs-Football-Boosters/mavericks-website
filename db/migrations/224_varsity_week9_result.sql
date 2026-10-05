-- 224_varsity_week9_result.sql
--
-- Game 6, Fri 2 Oct 2026, at Cedar Ridge (Cedar Ridge home) at KRAC:
--
--   Varsity at Cedar Ridge ....... LOST 29-70 (final)
--
-- Jeremy 2026-10-04: "mcneil varsity lost 70-29. Hard fought on rainy night
-- with lots of offensive excitement."
--
-- ⚠️ SCORE ORDER: Jeremy reported it theirs-first this time (70-29). our_score
-- FIRST as always (170/174/182/196/204/217): our_score = 29, their_score = 70,
-- `ResultCell` renders "L 29-70".
--
-- ── THIS IS WHAT TAKES THE BROADCAST LINKS DOWN (196's lesson) ──
-- 223 inserted the Cedar Ridge VYPE and YouTube rows with keep_after_final =
-- false. Marking the game final IS the takedown. Verify block asserts it.
--
-- ⚠️ The Thu Oct 1 JV and freshman games stay 'scheduled'. No result supplied.
-- Five weeks of sub-varsity results outstanding (Sep 3, 10, 17, 23, Oct 1).
--
-- DB-ONLY, NO DEPLOY. /schedule/games/* reads at request time.
-- Rollback: 224_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-02 19:00 America/Chicago'
     and opponent = 'Cedar Ridge High School'
     and result_status = 'scheduled';
  if n <> 1 then
    raise exception 'varsity Oct 2 at Cedar Ridge not found as scheduled (found %)', n;
  end if;
end $$;

update games
   set result_status = 'final', our_score = 29, their_score = 70, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-10-02 19:00 America/Chicago'
   and opponent = 'Cedar Ridge High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-02 19:00 America/Chicago'
     and result_status = 'final' and our_score = 29 and their_score = 70;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  select count(*) into n from game_broadcasts b
    join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-10-02 19:00 America/Chicago'
     and b.keep_after_final;
  if n <> 0 then raise exception '% Cedar Ridge broadcast row(s) would survive the final', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and result_status = 'scheduled' and game_date < now()
     and coalesce(notes, '') <> 'Scrimmage';
  if n <> 0 then
    raise exception '% past varsity regular-season game(s) still marked scheduled', n;
  end if;
end $$;

commit;

-- 238_varsity_senior_night_result.sql
--
-- Senior Night, Fri 9 Oct 2026, varsity HOME vs Stony Point at KRAC:
--
--   Varsity vs Stony Point ....... LOST 39-57 (final)
--
-- Jeremy 2026-10-12: "mcneil lost again. 57-39". Theirs-first as reported;
-- our_score FIRST as always: our_score = 39, their_score = 57, renders L 39-57.
--
-- Marking it final retires the 234 Stony Point VYPE/YouTube rows
-- (keep_after_final = false, asserted). Thu Oct 8 JV and freshman results not
-- supplied and stay 'scheduled' (six weeks of sub-varsity results outstanding).
--
-- DB-ONLY, NO DEPLOY. Rollback: 238_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-09 19:00 America/Chicago'
     and opponent = 'Stony Point High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'varsity Oct 9 vs Stony Point not found as scheduled (%)', n; end if;
end $$;

update games
   set result_status = 'final', our_score = 39, their_score = 57, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-10-09 19:00 America/Chicago'
   and opponent = 'Stony Point High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-09 19:00 America/Chicago'
     and result_status = 'final' and our_score = 39 and their_score = 57;
  if n <> 1 then raise exception 'varsity result did not take'; end if;

  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-10-09 19:00 America/Chicago' and b.keep_after_final;
  if n <> 0 then raise exception '% Stony Point broadcast row(s) would survive the final', n; end if;
end $$;

commit;

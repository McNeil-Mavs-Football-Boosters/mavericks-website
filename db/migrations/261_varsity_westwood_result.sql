-- 261_varsity_westwood_result.sql
--
-- Season finale, Fri 30 Oct 2026, varsity AT Westwood:
--
--   Varsity at Westwood .......... LOST 33-63 (final)
--
-- Jeremy 2026-11-10: "last game of the season the mavericks lost 33 to 63".
-- our_score = 33, their_score = 63, renders L 33-63. No Westwood broadcast
-- rows exist, so nothing retires. JV/freshman results not supplied.
--
-- DB-ONLY, NO DEPLOY. Rollback: 261_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-30 19:00 America/Chicago'
     and opponent = 'Westwood High School' and result_status = 'scheduled';
  if n <> 1 then raise exception 'varsity Oct 30 at Westwood not found as scheduled (%)', n; end if;
end $$;

update games
   set result_status = 'final', our_score = 33, their_score = 63, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-10-30 19:00 America/Chicago'
   and opponent = 'Westwood High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-10-30 19:00 America/Chicago'
     and result_status = 'final' and our_score = 33 and their_score = 63;
  if n <> 1 then raise exception 'varsity result did not take'; end if;
end $$;

commit;

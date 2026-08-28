-- 170_rollback.sql — returns the three Week 4 rows to 'scheduled' with no score.

begin;

update games
set result_status = 'scheduled', our_score = null, their_score = null
where year = '2026-27'
  and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
  and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
  and opponent = 'Austin Bowie High School';

do $$
declare n int;
begin
  select count(*) into n from games
   where year='2026-27'
     and game_date >= timestamptz '2026-08-27 00:00 America/Chicago'
     and game_date <  timestamptz '2026-08-28 00:00 America/Chicago'
     and result_status = 'scheduled' and our_score is null and their_score is null;
  if n <> 3 then raise exception 'expected 3 Week 4 rows back to scheduled, found %', n; end if;
end $$;

commit;

-- 182_rollback.sql
--
-- Returns the Sep 4 varsity game to 'scheduled' with no score. That also brings
-- the two Sep 4 broadcast links back onto the row, since they are hidden by the
-- final state rather than by their own flags.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and result_status = 'final' and our_score = 24 and their_score = 30;
  if n <> 1 then raise exception 'Sep 4 varsity result not as 182 left it (found %)', n; end if;
end $$;

update games
   set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-09-04 19:00 America/Chicago'
   and opponent = 'Lake Belton High School';

commit;

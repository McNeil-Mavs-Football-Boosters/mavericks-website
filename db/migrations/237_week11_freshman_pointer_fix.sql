-- 237_week11_freshman_pointer_fix.sql
--
-- 235's closing pointer said "freshmen Thursday Oct 15 at 5:00 and 6:30 p.m."
-- That read BOTH freshman `games` rows, but there is no Blue team this season
-- (freshman_has_blue = false; the 5:00 row is the hidden Blue row). Also, the
-- photo of Coach's Week 11 sheet is cut off before any game times, so the
-- freshman kickoff is NOT confirmed by his graphic (155's rule). The pointer now
-- names the place only and defers the time to the Games schedule.
-- JV 6:00 home and varsity 7:00 at Chaparral are unchanged (they match `games`
-- and are not per-week freshman slots).
-- DB-ONLY, NO DEPLOY. Rollback: 237_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%freshmen Thursday Oct 15 at 5:00 and 6:30 p.m. at Chaparral Stadium%';
  if n <> 3 then raise exception 'expected 3 bodies with the bad pointer, found %', n; end if;
end $$;

update practice_schedules
   set body = replace(body,
     'freshmen Thursday Oct 15 at 5:00 and 6:30 p.m. at Chaparral Stadium',
     'freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)'),
       updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%5:00 and 6:30%' or body not like '%Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)%');
  if n <> 0 then raise exception '% bodies not fixed', n; end if;
end $$;

commit;

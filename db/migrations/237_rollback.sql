-- 237_rollback.sql
begin;
update practice_schedules
   set body = replace(body,
     'freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)',
     'freshmen Thursday Oct 15 at 5:00 and 6:30 p.m. at Chaparral Stadium'),
       updated_at = now()
 where year = '2026-27';
commit;

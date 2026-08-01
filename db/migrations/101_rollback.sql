-- 101_rollback.sql
-- Restores the migration-077 preseason bodies captured from live Supabase
-- immediately before 101 was applied. Reverts Coach's week-1 corrections.

begin;

update practice_schedules
set body = $body$Varsity and JV practice together. Times are AM unless noted and are subject to change. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 3 | 7:30–11:00 | First day of practice |
| Tue Aug 4 | 6:00–9:30 | |
| Wed Aug 5 | 7:30–11:00 | |
| Thu Aug 6 | 7:30–11:00 | |
| Fri Aug 7 | 7:30–11:00 | Pool party 5:00–8:00 PM |
| Sat Aug 8 | 7:30–9:30 | Intrasquad scrimmage |
| Mon Aug 10 | 6:30–10:00 | |
| Tue Aug 11 | 6:30–10:00 | |
| Wed Aug 12 | 6:30–10:00 | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 7:00–10:00 | |
| Sat Aug 15 | 9:00–11:00 | |
| Mon Aug 17 | 6:30–10:00 | |
| Tue Aug 18 | 6:30–10:00 | |
| Wed Aug 19 | 6:20–8:15 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 7:00–8:00 | Picture day |
| Mon Aug 24 | 6:00–8:15 | |
| Tue Aug 25 | 6:00–8:15 | |
| Wed Aug 26 | 6:20–8:15 | |
| Thu Aug 27 | 7:50–8:30 | |
| Fri Aug 28 | See Games | Game 1 at Bowie (away) |
$body$
where year = '2026-27'
  and team_level in ('varsity', 'jv');

update practice_schedules
set body = $body$Freshmen practice times. Times are subject to change. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 3 | 10:00–12:00 | First day of practice |
| Tue Aug 4 | 8:30–10:30 (or 6:30–8:30 PM) | |
| Wed Aug 5 | 10:00–12:00 | |
| Thu Aug 6 | 10:00–12:00 | |
| Fri Aug 7 | 10:00–12:00 | Pool party 5:00–8:00 PM |
| Sat Aug 8 | 9:00–10:30 | Intrasquad scrimmage |
| Mon Aug 10 | 9:00–11:00 | |
| Tue Aug 11 | 9:00–11:00 | |
| Wed Aug 12 | 9:00–11:00 (or 6:30–8:30 PM) | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 9:00–11:00 | |
| Sat Aug 15 | No practice | |
| Mon Aug 17 | 9:00–11:00 | |
| Tue Aug 18 | 9:00–11:00 | |
| Wed Aug 19 | 8:10–9:45 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 8:00–10:15 | Picture day |
| Mon Aug 24 | 8:10–9:50 | |
| Tue Aug 25 | 8:10–9:50 | |
| Wed Aug 26 | 8:10–9:50 | |
| Thu Aug 27 | 8:45–9:50 | |
| Fri Aug 28 | 8:30–9:50 | Game 1 at Bowie (away) |
$body$
where year = '2026-27'
  and team_level = 'freshman';

commit;

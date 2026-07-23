-- 077_practice_schedules_2026_preseason.sql
--
-- Seeds the 2026-27 preseason practice schedule (from the coaches' July-August
-- 2026 calendar). Player-facing detail only: daily team practice times + key
-- markers (first day of practice/school, picture day, intrasquad scrimmage,
-- pool party). Coach-internal items (PD, coaches meetings, work week, scout
-- input, class periods) are intentionally omitted.
--
-- Year is 2026-27: the practice page now reads current_schedule_year (the season
-- being played), matching games/coaches — not current_year (the roster year).
-- Varsity and JV practice together, so they share one body; Freshmen differ.
-- Opponent scrimmages + Game 1 live on the games schedule (migration 078); the
-- tables here just point to it on those days.
--
-- Idempotent: INSERT-if-absent on (year, team_level).

BEGIN;

-- Varsity + JV (identical times) --------------------------------------------
INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'varsity', $body$Varsity and JV practice together. Times are AM unless noted and are subject to change. See the Games schedule for scrimmages and Game 1.

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
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='varsity');

INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'jv', $body$Varsity and JV practice together. Times are AM unless noted and are subject to change. See the Games schedule for scrimmages and Game 1.

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
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='jv');

-- Freshmen ------------------------------------------------------------------
INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'freshman', $body$Freshmen practice times. Times are subject to change. See the Games schedule for scrimmages and Game 1.

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
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='freshman');

COMMIT;

-- 101_practice_week1_from_coach.sql
--
-- Coach's "MAV FOOTBALL WEEKLY SCHEDULE, August 3-9, 2026" doc (received
-- 2026-07-31) is authoritative for week 1. It CONFLICTS with the migration-077
-- preseason seed in three places, so this is a correction, not just an add:
--
--   Tue Aug 4 upperclassmen : was 6:00-9:30  -> 5:40 arrival / 5:55 field / 7:45 end
--   Tue Aug 4 freshmen      : was 8:30-10:30 AM (or 6:30-8:30 PM) -> evening ONLY
--   Sat Aug 8 scrimmages    : was V/JV 7:30-9:30 + F 9:00-10:30
--                             -> V/JV 7:30-8:30 + F 9:00-10:00
--
-- Week 1 gains arrival-vs-on-field times, Monday equipment pickup, and Sunday
-- Aug 9 as an explicit off day. Everything after Aug 9 is unchanged from 077
-- but now sits under a "tentative" heading per Jeremy.
--
-- Varsity and JV share identical bodies (Coach's doc addresses them jointly as
-- UPPERCLASSMEN (SOPH / JR / SR)), matching the 077 convention.

begin;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 1 — August 3–9

| Day | Arrival | On field | Ends | Notes |
|---|---|---|---|---|
| Mon Aug 3 | 7:10 a.m. | 7:30 a.m. | 11:00 a.m. | Equipment pickup 6:45 a.m. for players who still need it |
| Tue Aug 4 | 5:40 a.m. | 5:55 a.m. | 7:45 a.m. | |
| Wed Aug 5 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | |
| Thu Aug 6 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | |
| Fri Aug 7 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | Pool party 5:00–8:00 p.m. at Avery Ranch |
| Sat Aug 8 | 6:45 a.m. | 7:00 a.m. | 8:30 a.m. | Upperclassmen intra-squad scrimmage 7:30–8:30 a.m. |
| Sun Aug 9 | Off day | Off day | Off day | Recover, reset and prepare |

## After Week 1 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
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
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 1 — August 3–9

| Day | Arrival | On field | Ends | Notes |
|---|---|---|---|---|
| Mon Aug 3 | — | 10:00 a.m. | 12:00 p.m. | Equipment pickup 9:20 a.m. for players who still need it |
| Tue Aug 4 | 6:30 p.m. | 6:45 p.m. | 8:15 p.m. | Evening practice |
| Wed Aug 5 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | |
| Thu Aug 6 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | |
| Fri Aug 7 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | Pool party 5:00–8:00 p.m. at Avery Ranch |
| Sat Aug 8 | 8:30 a.m. | 8:45 a.m. | 10:00 a.m. | Freshman intra-squad scrimmage 9:00–10:00 a.m. |
| Sun Aug 9 | Off day | Off day | Off day | Recover, reset and prepare |

## After Week 1 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
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

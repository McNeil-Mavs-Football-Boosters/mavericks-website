-- 118_practice_week2_earlier.sql
--
-- Coach moved next week's practice EARLIER for both groups because of a
-- teacher/coach professional development change. Relayed by Jeremy 2026-08-08,
-- ahead of the Weekly MAV Reminder going out 2026-08-09.
--
--   Upperclassmen : arrive 6:00, on field 6:25, done 9:50  (was 6:30-10:00)
--   Freshmen      : arrive 8:35, on field 8:55, done 10:30 (was 9:00-11:00)
--
-- Week 1 (Aug 3-9) is REMOVED — it has run, and Jeremy asked for it to come off.
-- Next week is promoted out of the "tentative" bullet list into real day blocks
-- with arrival / on-field / end times, matching how Week 1 was presented.
--
-- ⚠️ SCOPE OF THE NEW TIMES. Coach supplied ONE set of times for "next week",
-- so they are applied to the four weekday practices (Mon 10, Tue 11, Wed 12,
-- Fri 14). Thursday Aug 13 is the Hendrickson scrimmage, not a practice, and is
-- untouched. SATURDAY AUG 15 IS ALSO UNTOUCHED (upperclassmen 9:00-11:00,
-- freshmen no practice) because Coach did not mention it — the section says so
-- in-copy rather than silently implying Saturday moved too. If Coach's reminder
-- tomorrow says otherwise, Friday and Saturday are the two to re-check.
--
-- The freshman "Wed Aug 12 — 9:00-11:00 (or 6:30-8:30 PM)" alternative is gone:
-- the new time is a specific commitment, not a choice of two.
--
-- Bodies were BUILT BY TRANSFORMING THE LIVE ROWS, not retyped: the Aug 17-28
-- tentative list is carried across verbatim. Asserted before writing that all
-- ten remaining tentative dates survive, both scrimmage references survive, no
-- Week 1 content remains, and each new time appears on exactly four days.
-- 118_rollback.sql restores the previous bodies byte-exact.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Saturday, Aug 15
- **9:00–11:00 a.m.** — Practice

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Saturday, Aug 15
- **9:00–11:00 a.m.** — Practice

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Tuesday, Aug 11
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Wednesday, Aug 12
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Saturday, Aug 15
No practice.

## After Week 2 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 9:00–11:00
- **Tue Aug 18** — 9:00–11:00
- **Wed Aug 19** — 8:10–9:45 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 8:00–10:15 · Picture day
- **Mon Aug 24** — 8:10–9:50
- **Tue Aug 25** — 8:10–9:50
- **Wed Aug 26** — 8:10–9:50
- **Thu Aug 27** — 8:45–9:50
- **Fri Aug 28** — 8:30–9:50 · Game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'freshman';

commit;

-- Verification:
--   select team_level, body like '%Week 2%' as has_wk2, body like '%Week 1%' as has_wk1
--   from practice_schedules where year='2026-27';
--   -> has_wk2 t, has_wk1 f for all three
--
-- /schedule/practice/* reads at request time, so this is live with no deploy.

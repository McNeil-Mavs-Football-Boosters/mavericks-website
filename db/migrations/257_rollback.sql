-- 257_rollback.sql
-- Restores the Week 12 practice bodies byte-for-byte and the Round Rock varsity / Westwood JV games rows as they stood before 257. Generated from the live rows before apply.
begin;
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 19.** Practice is still on, starting 7:45 a.m. **No morning practice Thursday or Friday** this week. Friday is Homecoming.

## Week 12 — October 19–23

Times below are Coach''s published MAV Football Weekly Schedule for October 19–23.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way. This week it runs **11:00 a.m.–12:10 p.m.**

### Monday, Oct 19 — no school
- **7:45 a.m.** — Arrival
- **7:45–11:00 a.m.** — Practice and team activities

### Tuesday, Oct 20
- **6:15 a.m.** — Arrival
- **6:30–8:15 a.m.** — Morning practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Wednesday, Oct 21
- **6:45 a.m.** — Arrival
- **7:00–8:15 a.m.** — Practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Thursday, Oct 22 — JV game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 23 — Homecoming, varsity game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice

### Saturday, Oct 24 – Sunday, Oct 25
Not on Coach''s schedule this week.

**Reminder from Coach:** arrive on time, dressed and ready. Varsity and JV athletes should be ready for athletic-period activities at 11:00 a.m.

## After Week 12

Week 13 times will be posted when Coach publishes that schedule.

See the Games schedule for the Round Rock game — JV Thursday Oct 22 at 5:30 p.m. at Round Rock High School (Dragon Stadium), freshmen Thursday Oct 22 at 5:30 p.m. at Maverick Stadium (home), varsity Homecoming Friday Oct 23 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'varsity';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 19.** Practice is still on, starting 7:45 a.m. **No morning practice Thursday or Friday** this week. Friday is Homecoming.

## Week 12 — October 19–23

Times below are Coach''s published MAV Football Weekly Schedule for October 19–23.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way. This week it runs **11:00 a.m.–12:10 p.m.**

### Monday, Oct 19 — no school
- **7:45 a.m.** — Arrival
- **7:45–11:00 a.m.** — Practice and team activities

### Tuesday, Oct 20
- **6:15 a.m.** — Arrival
- **6:30–8:15 a.m.** — Morning practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Wednesday, Oct 21
- **6:45 a.m.** — Arrival
- **7:00–8:15 a.m.** — Practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Thursday, Oct 22 — JV game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 23 — Homecoming, varsity game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice

### Saturday, Oct 24 – Sunday, Oct 25
Not on Coach''s schedule this week.

**Reminder from Coach:** arrive on time, dressed and ready. Varsity and JV athletes should be ready for athletic-period activities at 11:00 a.m.

## After Week 12

Week 13 times will be posted when Coach publishes that schedule.

See the Games schedule for the Round Rock game — JV Thursday Oct 22 at 5:30 p.m. at Round Rock High School (Dragon Stadium), freshmen Thursday Oct 22 at 5:30 p.m. at Maverick Stadium (home), varsity Homecoming Friday Oct 23 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'jv';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Monday Oct 19.** Practice is still on, 10:00 a.m. to noon.

## Week 12 — October 19–23

Times below are Coach''s published MAV Football Weekly Schedule for October 19–23.

After practice, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Oct 19 — no school
- **9:45 a.m.** — Arrival
- **10:00 a.m.–12:00 p.m.** — Practice

### Tuesday, Oct 20
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Wednesday, Oct 21
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Thursday, Oct 22 — game day
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Friday, Oct 23 — Homecoming
- **8:25 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Saturday, Oct 24 – Sunday, Oct 25
Not on Coach''s schedule this week.

## After Week 12

Week 13 times will be posted when Coach publishes that schedule.

See the Games schedule for the Round Rock game — freshmen Thursday Oct 22 at 5:30 p.m. at Maverick Stadium (home), JV Thursday Oct 22 at 5:30 p.m. at Round Rock High School (Dragon Stadium), varsity Homecoming Friday Oct 23 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'freshman';
update games set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now() where year = '2026-27' and team_level = 'varsity' and opponent = 'Round Rock High School' and game_date = timestamptz '2026-10-23 19:00 America/Chicago';
update games set game_date = timestamptz '2026-10-29 18:00 America/Chicago', updated_at = now() where year = '2026-27' and team_level = 'jv' and opponent = 'Westwood High School' and game_date = timestamptz '2026-10-29 17:30 America/Chicago';
commit;

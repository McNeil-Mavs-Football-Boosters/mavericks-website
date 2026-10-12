-- 235_rollback.sql
-- Restores the Week 10 bodies (with 229's Monday Oct 12 block) byte-for-byte.
-- Generated from the live rows immediately before 235 was applied.
begin;
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

🚨 **No school Friday Oct 9 (Senior Night).** Friday is a 9:50 a.m. arrival for a walk-through, then a second arrival at 2:00 p.m. Morning times also change day to day this week starting Tuesday, so check each day.

## Week 10 — October 5–9

Times below are Coach''s published MAV Football Weekly Schedule for October 5–9.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Oct 5
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — Meetings
- **6:25–8:15 a.m.** — On the field
- **10:45 a.m.–12:10 p.m.** — Period 2/6: weights and film

### Tuesday, Oct 6
- **6:15 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **8:15 a.m.** — Practice complete
- **10:45 a.m.–12:10 p.m.** — Period 2/6: stretch and film

### Wednesday, Oct 7
- **6:45 a.m.** — Arrival
- **7:00 a.m.** — On the field
- **8:15 a.m.** — Practice complete
- **10:45 a.m.–12:10 p.m.** — Period 2/6: weights and film

### Thursday, Oct 8 — JV game day
**No morning practice.**
- **10:45 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 9 — Senior Night, no school
- **9:50 a.m.** — Arrival
- **10:00–11:00 a.m.** — Walk-through (breakfast tacos provided)
- **2:00 p.m.** — Second arrival

### Saturday, Oct 10 – Sunday, Oct 11
Not on Coach''s schedule this week.

## After Week 10

### Monday, Oct 12: no school (teacher professional development day)
Practice is still on.
- **6:45 a.m.**: Arrival
- **7:00 a.m.**: On the field
- **10:00 a.m.**: Done

The rest of Week 11 will be posted when Coach publishes that schedule.

See the Games schedule for the Stony Point game — JV Thursday Oct 8 at 6:00 p.m. at Stony Point, freshmen Thursday Oct 8 at 5:30 p.m. at Maverick Stadium (home), varsity Senior Night Friday Oct 9 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'varsity';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

🚨 **No school Friday Oct 9 (Senior Night).** Friday is a 9:50 a.m. arrival for a walk-through, then a second arrival at 2:00 p.m. Morning times also change day to day this week starting Tuesday, so check each day.

## Week 10 — October 5–9

Times below are Coach''s published MAV Football Weekly Schedule for October 5–9.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Oct 5
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — Meetings
- **6:25–8:15 a.m.** — On the field
- **10:45 a.m.–12:10 p.m.** — Period 2/6: weights and film

### Tuesday, Oct 6
- **6:15 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **8:15 a.m.** — Practice complete
- **10:45 a.m.–12:10 p.m.** — Period 2/6: stretch and film

### Wednesday, Oct 7
- **6:45 a.m.** — Arrival
- **7:00 a.m.** — On the field
- **8:15 a.m.** — Practice complete
- **10:45 a.m.–12:10 p.m.** — Period 2/6: weights and film

### Thursday, Oct 8 — JV game day
**No morning practice.**
- **10:45 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 9 — Senior Night, no school
- **9:50 a.m.** — Arrival
- **10:00–11:00 a.m.** — Walk-through (breakfast tacos provided)
- **2:00 p.m.** — Second arrival

### Saturday, Oct 10 – Sunday, Oct 11
Not on Coach''s schedule this week.

## After Week 10

### Monday, Oct 12: no school (teacher professional development day)
Practice is still on.
- **6:45 a.m.**: Arrival
- **7:00 a.m.**: On the field
- **10:00 a.m.**: Done

The rest of Week 11 will be posted when Coach publishes that schedule.

See the Games schedule for the Stony Point game — JV Thursday Oct 8 at 6:00 p.m. at Stony Point, freshmen Thursday Oct 8 at 5:30 p.m. at Maverick Stadium (home), varsity Senior Night Friday Oct 9 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'jv';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Friday Oct 9.** Coach''s schedule lists no freshman session that day.

## Week 10 — October 5–9

Times below are Coach''s published MAV Football Weekly Schedule for October 5–9.

After practice, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Oct 5
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Tuesday, Oct 6
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Wednesday, Oct 7
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Thursday, Oct 8 — game day
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Friday, Oct 9 — no school
Not on Coach''s schedule for freshmen.

### Saturday, Oct 10 – Sunday, Oct 11
Not on Coach''s schedule this week.

## After Week 10

### Monday, Oct 12: no school (teacher professional development day)
Practice is still on.
- **9:15 a.m.**: Arrival
- **9:30 a.m.**: On the field
- **10:50 a.m.**: Done

The rest of Week 11 will be posted when Coach publishes that schedule.

See the Games schedule for the Stony Point game — freshmen Thursday Oct 8 at 5:30 p.m. at Maverick Stadium (home), JV Thursday Oct 8 at 6:00 p.m. at Stony Point, varsity Senior Night Friday Oct 9 at 7:00 p.m. at Kelly Reeves Athletic Complex.', updated_at = now() where year = '2026-27' and team_level = 'freshman';
commit;

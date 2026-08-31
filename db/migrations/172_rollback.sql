-- 172_rollback.sql — restores the Week 4 (Aug 24-30) practice bodies.
--
-- Regenerated from 153's exact text, so rolling back 172 lands on precisely
-- what 153 shipped. If a later migration has since edited a Week 5 body, this
-- still overwrites it wholesale -- that is the same trade 153 made.

begin;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together. **Be on time to class.**

## Week 4 — August 24–30

Times below are Coach's published MAV Football Weekly Schedule for August 24–30.

**P2/P6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Aug 24
- **5:45 a.m.** — Arrival
- **6:00–6:20 a.m.** — Meetings
- **6:25 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Tuesday, Aug 25
- **5:45 a.m.** — Arrival
- **6:00 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Wednesday, Aug 26
- **6:30 a.m.** — Arrival
- **6:45 a.m.** — On the field
- **8:15 a.m.** — Practice ends
- Shower / get ready — do not be late to 1st period
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Thursday, Aug 27
**No early practice.**
- **11:15 a.m.–12:15 p.m.** — P2/P6, on the field
- **Team dinner** — time to be announced

### Friday, Aug 28
**No early practice.**
- **11:15 a.m.–12:00 p.m.** — P2/P6 — game day walkthrough / JV film

### Saturday, Aug 29
**Athletes: no scheduled activities.**
- **11:00 a.m.** — Coaches: scout input complete
- **4:00 p.m.** — Varsity grades sent to athletes

### Sunday, Aug 30
**Coaches workday.** Athletes: no scheduled activities.
- **11:30 a.m.** — Coordinators meeting
- **12:00 p.m.** — Special teams meeting
- Game preparation until completion

## After Week 4

Week 5 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. **Be on time to class.**

## Week 4 — August 24–30

Times below are Coach's published MAV Football Weekly Schedule for August 24–30.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Aug 24
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Tuesday, Aug 25
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Wednesday, Aug 26
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Thursday, Aug 27
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — On the field
- **9:30 a.m.** — Practice ends
- **9:45–10:05 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Friday, Aug 28
- **8:45 a.m.** — Arrival
- **9:00–10:00 a.m.** — Game film
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Saturday, Aug 29
**Athletes: no scheduled activities.**

### Sunday, Aug 30
**Athletes: no scheduled activities.** Coaches workday.

## After Week 4

Week 5 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

commit;

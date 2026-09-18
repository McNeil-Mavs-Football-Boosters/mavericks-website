-- 202_rollback.sql
--
-- Restores the Week 6 bodies exactly as 181 wrote them (Week 7 was never
-- posted, so Week 6 is the previous state). Guarded on the bodies being Week 8.

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 8 — September 21–25%';
  if n <> 3 then raise exception 'expected 3 Week 8 bodies, found % (202 not applied?)', n; end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together. **Be on time to class.**

🚨 **Labor Day, Monday Sept 7 — there IS practice.** Arrival **6:40 a.m.**, practice ends **10:20 a.m.** Full times under Monday below.

## Week 6 — September 7–13

Times below are Coach's published MAV Football Weekly Schedule for September 7–13.

**P2/P6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

⚠️ **P2/P6 starts at 10:45 a.m. this week — half an hour earlier than last week.** Coach added a "flex out" line to every day it runs.

### Monday, Sep 7 — Labor Day practice
- **6:40 a.m.** — Arrival
- **7:00–7:20 a.m.** — Meetings
- **7:25 a.m.** — On the field / stretch lines
- **10:20 a.m.** — Practice ends

### Tuesday, Sep 8
- **5:45 a.m.** — Arrival
- **6:00 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:10 p.m.** — P2/P6, on the field

### Wednesday, Sep 9
- **6:15 a.m.** — Arrival
- **6:30 a.m.** — On the field
- **8:15 a.m.** — Practice ends
- Shower / get ready — do not be late to 1st period
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:10 p.m.** — P2/P6, on the field

### Thursday, Sep 10
**No early practice.**
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:15 p.m.** — P2/P6, on the field
- **Team dinner** — time to be announced

### Friday, Sep 11
**No early practice.**
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:00 p.m.** — P2/P6 — game day walkthrough / JV film

### Saturday, Sep 12
**Athletes: no scheduled activities.**
- **11:00 a.m.** — Coaches: scout input complete
- **4:00 p.m.** — Varsity grades sent to athletes

### Sunday, Sep 13
**Coaches workday.** Athletes: no scheduled activities.
- **11:30 a.m.** — Coordinators meeting
- **12:00 p.m.** — Special teams meeting
- Game preparation until completion

## After Week 6

Week 7 times will be posted when Coach publishes that schedule.

See the Games schedule for Game 3 vs Rouse — freshmen and JV Thursday Sep 10, varsity Friday Sep 11 at 7:00 p.m. at Gupton Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. **Be on time to class.**

🚨 **Labor Day, Monday Sept 7 — there IS practice.** Arrival **9:00 a.m.**, practice ends **11:20 a.m.** Full times under Monday below.

## Week 6 — September 7–13

Times below are Coach's published MAV Football Weekly Schedule for September 7–13.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Sep 7 — Labor Day practice
- **9:00 a.m.** — Arrival
- **9:25 a.m.** — On the field / stretch lines
- **11:20 a.m.** — Practice ends

### Tuesday, Sep 8
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Wednesday, Sep 9
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Thursday, Sep 10
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — On the field
- **9:30 a.m.** — Practice ends
- **9:45–10:05 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Friday, Sep 11
- **8:45 a.m.** — Arrival
- **9:00–10:00 a.m.** — Game film
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Saturday, Sep 12
**Athletes: no scheduled activities.**

### Sunday, Sep 13
**Athletes: no scheduled activities.** Coaches workday.

## After Week 6

Week 7 times will be posted when Coach publishes that schedule.

See the Games schedule for Game 3 vs Rouse — freshmen and JV Thursday Sep 10, varsity Friday Sep 11 at 7:00 p.m. at Gupton Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';


do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 6 — September 7–13%';
  if n <> 3 then raise exception 'expected 3 Week 6 bodies after rollback, found %', n; end if;
end $$;

commit;

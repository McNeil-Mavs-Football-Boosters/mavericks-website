-- 226_rollback.sql
--
-- Restores the Week 9 bodies exactly as they stood before 226 (218), captured
-- from the live rows 2026-10-04. Guarded on the bodies being Week 10.

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 10 — October 5–9%';
  if n <> 3 then raise exception 'expected 3 Week 10 bodies, found %', n; end if;
end $$;

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

🚨 **Monday Sep 28 is the last day before eligibility reports.** Flex out is for tutoring / grades that day.

## Week 9 — September 28–October 2

Times below are Coach's published MAV Football Weekly Schedule for September 28–October 2.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

**Flex out** — Coach's note: athletes assigned to flex must report at **10:45 a.m.**

### Monday, Sep 28 — last day before eligibility reports
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — Meetings
- **6:00–8:00 a.m.** — JV on the field
- Period 2/6
- Flex out for tutoring / grades
- **10:45 a.m.** — If not in tutoring: weights
- Meetings after weights

### Tuesday, Sep 29
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — On the field
- Film
- Period 2/6
- **10:45 a.m.** — Flex out
- Stretch and film

### Wednesday, Sep 30
- **6:15 a.m.** — Arrival
- **6:30 a.m.** — Varsity & JV on the field
- Period 2/6
- **10:45 a.m.** — Flex out and report to the weight room
- Weights during the period

### Thursday, Oct 1 — JV game day
**No morning practice.**
- Period 2/6
- **10:45 a.m.** — Flex out
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 2 — varsity game day
**No morning practice.**
- Period 2/6
- **10:45 a.m.** — Flex out

### Saturday, Oct 3 – Sunday, Oct 4
Not on Coach's schedule this week.

## After Week 9

Week 10 times will be posted when Coach publishes that schedule.

See the Games schedule for the Cedar Ridge game — JV Thursday Oct 1 at 5:30 p.m. at Maverick Stadium (home), freshmen Thursday Oct 1 at 6:30 p.m. at Cedar Ridge, varsity Friday Oct 2 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **Extra session Monday:** weight room after school, **4:30–5:15 p.m.**

## Week 9 — September 28–October 2

Times below are Coach's published MAV Football Weekly Schedule for September 28–October 2.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Sep 28
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field / practice
- **9:45 a.m.** — Breakfast
- **4:30–5:15 p.m.** — Weight room after school

### Tuesday, Sep 29
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field / practice
- **9:45 a.m.** — Breakfast

### Wednesday, Sep 30
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field / practice
- **9:45 a.m.** — Breakfast

### Thursday, Oct 1 — game day
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field / practice
- **9:45 a.m.** — Breakfast

### Friday, Oct 2
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — Weights and film
- **9:45 a.m.** — Breakfast

### Saturday, Oct 3 – Sunday, Oct 4
Not on Coach's schedule this week.

## After Week 9

Week 10 times will be posted when Coach publishes that schedule.

See the Games schedule for the Cedar Ridge game — freshmen Thursday Oct 1 at 6:30 p.m. at Cedar Ridge, JV Thursday Oct 1 at 5:30 p.m. at Maverick Stadium (home), varsity Friday Oct 2 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 9 — September 28–October 2%';
  if n <> 3 then raise exception 'rollback did not restore 3 Week 9 bodies (%)', n; end if;
end $$;

commit;

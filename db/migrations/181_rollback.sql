-- 181_rollback.sql
--
-- Restores the Week 5 (Aug 31 - Sep 6) practice bodies exactly as they stood
-- after migration 175, i.e. Week 5 days plus the "After Week 5" Labor Day block
-- carrying 175's superseded times (varsity/JV 6:30/7:00, freshmen 8:30/9:00).
--
-- Captured verbatim from the live rows immediately before 181 was applied.
--
-- Guarded on the bodies actually being on Week 6, so running this twice, or on a
-- later week, fails loudly instead of clobbering it.

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 6 — September 7–13%';
  if n <> 3 then
    raise exception 'expected 3 bodies on Week 6, found % (not 181 to roll back?)', n;
  end if;
end $$;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together. **Be on time to class.**

🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **6:30 a.m.**; practice begins at **7:00 a.m.**

## Week 5 — August 31–September 6

Times below are Coach's published MAV Football Weekly Schedule for August 31–September 6.

**P2/P6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Aug 31
- **5:45 a.m.** — Arrival
- **6:00–6:20 a.m.** — Meetings
- **6:25 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Tuesday, Sep 1
- **5:45 a.m.** — Arrival
- **6:00 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Wednesday, Sep 2
- **6:15 a.m.** — Arrival
- **6:30 a.m.** — On the field
- **8:15 a.m.** — Practice ends
- Shower / get ready — do not be late to 1st period
- **11:15 a.m.–12:10 p.m.** — P2/P6, on the field
- Lunch after — all C lunch

### Thursday, Sep 3
**No early practice.**
- **11:15 a.m.–12:15 p.m.** — P2/P6, on the field
- **Team dinner** — time to be announced

### Friday, Sep 4
**No early practice.**
- **11:15 a.m.–12:00 p.m.** — P2/P6 — game day walkthrough / JV film

### Saturday, Sep 5
**Athletes: no scheduled activities.**
- **11:00 a.m.** — Coaches: scout input complete
- **4:00 p.m.** — Varsity grades sent to athletes

### Sunday, Sep 6
**Coaches workday.** Athletes: no scheduled activities.
- **11:30 a.m.** — Coordinators meeting
- **12:00 p.m.** — Special teams meeting
- Game preparation until completion

## After Week 5

**Labor Day, Monday Sept 7 — there is practice.**
- **6:30 a.m.** — Arrival, no later than
- **7:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.

See the Games schedule for Game 2 vs Lake Belton — freshmen and JV Thursday Sep 3, varsity Friday Sep 4.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. **Be on time to class.**

🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **8:30 a.m.**; practice begins at **9:00 a.m.**

## Week 5 — August 31–September 6

Times below are Coach's published MAV Football Weekly Schedule for August 31–September 6.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Aug 31
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Tuesday, Sep 1
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Wednesday, Sep 2
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Thursday, Sep 3
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — On the field
- **9:30 a.m.** — Practice ends
- **9:45–10:05 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Friday, Sep 4
- **8:45 a.m.** — Arrival
- **9:00–10:00 a.m.** — Game film
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Saturday, Sep 5
**Athletes: no scheduled activities.**

### Sunday, Sep 6
**Athletes: no scheduled activities.** Coaches workday.

## After Week 5

**Labor Day, Monday Sept 7 — there is practice.**
- **8:30 a.m.** — Arrival, no later than
- **9:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.

See the Games schedule for Game 2 vs Lake Belton — freshmen and JV Thursday Sep 3, varsity Friday Sep 4.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 5 — August 31–September 6%';
  if n <> 3 then raise exception 'expected 3 Week 5 bodies after rollback, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 6%';
  if n <> 0 then raise exception '% bodies still mention Week 6', n; end if;
end $$;

commit;

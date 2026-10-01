-- 218_rollback.sql
--
-- Restores the Week 8 bodies exactly as they stood before 218 (202 + 205-209
-- edits), captured from the live rows 2026-09-28. Guarded on the bodies being Week 9.

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 9 — September 28–October 2%';
  if n <> 3 then raise exception 'expected 3 Week 9 bodies, found % (218 not applied?)', n; end if;
end $$;

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **Games are a day early this week.** JV plays **Wednesday Sep 23 at 6:00 p.m.** at Cavalier Track and Field Stadium (Lake Travis) (not Cavalier Stadium) and varsity plays **Thursday Sep 24 at 7:00 p.m.** at Kelly Reeves. See the Games schedule.

## Week 8 — September 21–25

Times below are Coach's published MAV Football Weekly Schedule for September 21–25.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

**Flex out** — Coach's note: athletes assigned to flex must report at **10:45 a.m.**

### Monday, Sep 21
- **6:40 a.m.** — Arrival
- **7:00 a.m.** — Meetings
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice complete

### Tuesday, Sep 22
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — Ready on the field
- **6:05–8:10 a.m.** — Practice
- Period 2/6
- **10:45 a.m.** — Flex out for film

### Wednesday, Sep 23 — JV game day
**No morning practice.** (Changed by Coach Tuesday evening; his published schedule had a 5:40 a.m. session.)
- Period 2/6
- **10:45 a.m.** — Flex out for film
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Thursday, Sep 24 — varsity game day
**No morning practice.**
- Period 2/6
- **10:45 a.m.** — Varsity & JV flex out
- JV film during the period

### Friday, Sep 25
**No morning practice.**
- Period 2/6
- **10:45 a.m.** — Varsity & JV flex out
- Film and weights — varsity group

### Saturday, Sep 26 – Sunday, Sep 27
Not on Coach's schedule this week.

## After Week 8

Week 9 times will be posted when Coach publishes that schedule.

See the Games schedule for the Lake Travis game — freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Cavalier Track and Field Stadium (Lake Travis), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **The freshman game is Wednesday this week** (Sep 23), not Thursday. **Kickoff 5:30 p.m. at Maverick Stadium** (home). See the Games schedule.

## Week 8 — September 21–25

Times below are Coach's published MAV Football Weekly Schedule for September 21–25.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Sep 21
- **9:00 a.m.** — Arrival
- **9:15 a.m.** — On the field
- **11:00 a.m.** — Practice complete

### Tuesday, Sep 22
- **8:00 a.m.** — Arrival
- **8:25–9:25 a.m.** — Practice
- **9:25–10:10 a.m.** — Breakfast
- After breakfast — shower and prepare for class

### Wednesday, Sep 23 — game day
- **8:00 a.m.** — Arrival
- **8:25–9:25 a.m.** — Practice
- **9:25–10:10 a.m.** — Breakfast
- After breakfast — shower and prepare for class

### Thursday, Sep 24
- **8:00 a.m.** — Arrival
- **8:15 a.m.** — Film
- **8:45 a.m.** — Weights
- **9:30 a.m.** — Breakfast

### Friday, Sep 25
- **8:45 a.m.** — Arrival
- **9:00–9:45 a.m.** — Special teams walk-through

### Saturday, Sep 26 – Sunday, Sep 27
Not on Coach's schedule this week.

## After Week 8

Week 9 times will be posted when Coach publishes that schedule.

See the Games schedule for the Lake Travis game — freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Cavalier Track and Field Stadium (Lake Travis), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 8 — September 21–25%';
  if n <> 3 then raise exception 'expected 3 Week 8 bodies after rollback, found %', n; end if;
end $$;

commit;

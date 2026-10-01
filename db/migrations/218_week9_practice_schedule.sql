-- 218_week9_practice_schedule.sql
--
-- Week 9 (Sep 28 - Oct 2) practice times, from Coach's published MAV FOOTBALL
-- WEEKLY SCHEDULE for September 28-October 2 2026 ("ONE MAV NATION"). Jeremy
-- sent a photo of the doc on Coach's screen 2026-09-28. Replaces the Week 8
-- block in all three bodies.
--
-- Conventions from 153/172/181/202 kept without restating: Period 2/6 glossed
-- once at the top; whole body replaced, guarded on the body still being Week 8
-- so a re-run is a no-op; games live in `games` and only the closing block
-- points at them.
--
-- ── WHAT CHANGED FROM WEEK 8 ──
-- 1. Normal game week again: JV and freshmen THURSDAY Oct 1, varsity FRIDAY
--    Oct 2, so the "games are a day early" warning is gone.
-- 2. 🚨 MONDAY IS THE LAST DAY BEFORE ELIGIBILITY REPORTS. Coach prints it in
--    caps, with flex out for tutoring / grades and weights at 10:45 only for
--    athletes not in tutoring. Carried as a callout at the top and on Monday.
-- 3. Varsity/JV mornings: Mon 5:40 / 6:00 meetings / 6:00-8:00 JV on the field;
--    Tue 5:40 / 6:00; Wed 6:15 / 6:30. No morning practice Thu or Fri.
-- 4. Freshmen: 8:00 / 8:25 / 9:45 breakfast Mon-Thu, plus Monday 4:30-5:15 p.m.
--    weight room after school; Friday 8:30 / 8:45 weights and film / 9:45.
-- 5. Varsity team dinner Thu Oct 1 6:00-7:30 p.m. (lib/team-dinners.ts), one
--    line on Thursday in the varsity/JV body, same as 202.
-- 6. Closing pointer carries the kickoffs as they stand after 219 (JV 5:30 per
--    Coach's doc, was 6:00 in `games`); 219 is applied with this one.
-- 7. Coach writes "Kelley Reaves Athletic Complex"; the venue row's spelling
--    (Kelly Reeves) is kept.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 218_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 8 — September 21–25%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 8, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
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
  if n <> 3 then raise exception 'expected 3 Week 9 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 8 —%' or body like '%Lake Travis%');
  if n <> 0 then raise exception '% bodies still carry Week 8 text', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%eligibility reports%'
     and body like '%**6:00–8:00 a.m.** — JV on the field%'
     and body like '%**6:30 a.m.** — Varsity & JV on the field%'
     and body like '%Varsity team dinner%'
     and body not like '%4:30–5:15%';
  if n <> 2 then raise exception 'varsity/jv Week 9 body not as intended on both rows (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**4:30–5:15 p.m.** — Weight room after school%'
     and body like '%**8:45 a.m.** — Weights and film%'
     and body not like '%5:40 a.m.%'
     and body not like '%team dinner%';
  if n <> 1 then raise exception 'freshman Week 9 body not as intended (%)', n; end if;

  -- Games stay out of the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 9.*$', '', 's') ~ '(5:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;
end $$;

commit;

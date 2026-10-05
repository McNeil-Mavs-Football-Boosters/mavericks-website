-- 226_week10_practice_schedule.sql
--
-- Week 10 (Oct 5-9, Senior Night week) practice times, from Coach's published
-- MAV FOOTBALL WEEKLY SCHEDULE for October 5-9 2026 ("ONE MAV NATION"). Jeremy
-- sent a photo 2026-10-04: "No school on Friday... schedule this week is a
-- little different starting Tuesday." Replaces the Week 9 block in all three
-- bodies.
--
-- Conventions from 153/172/181/202/218 kept: Period 2/6 glossed once at the
-- top; whole body replaced, guarded on the body still being Week 9 so a re-run
-- is a no-op; games live in `games` and only the closing block points at them.
--
-- ── WHAT CHANGED FROM WEEK 9 ──
-- 1. 🚨 NO SCHOOL FRIDAY OCT 9 (Senior Night). Varsity/JV: 9:50 a.m. arrival,
--    10:00-11:00 walk-through with breakfast tacos, 2:00 p.m. second arrival.
--    Callout at the top. Freshmen: Coach's sheet lists no Friday session.
-- 2. Varsity/JV mornings move later each day from Tuesday: Mon 5:40 / 6:00
--    meetings / 6:25-8:15; Tue 6:15 / 6:25 / done 8:15; Wed 6:45 / 7:00 / done
--    8:15; Thu no morning practice.
-- 3. Coach now prints the period as a window, 10:45 a.m.-12:10 p.m., with what
--    happens in it (weights and film / stretch and film / practice). The
--    Week 9 "flex out at 10:45" line is not on this sheet and is not carried.
-- 4. Freshmen Mon-Thu: 8:00 / 8:25 / practice complete 9:35 (no breakfast line
--    on this sheet; Week 9's 9:45 breakfast is not carried).
-- 5. Varsity team dinner Thu Oct 8 6:00-7:30 p.m. (lib/team-dinners.ts), one
--    line on Thursday, same as 202/218.
-- 6. Closing pointer carries kickoffs as they stand after 225 (freshmen 5:30,
--    was 6:30 in `games`); 225 is applied with this one.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
-- Rollback: 226_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 9 — September 28–October 2%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 9, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

🚨 **No school Friday Oct 9 (Senior Night).** Friday is a 9:50 a.m. arrival for a walk-through, then a second arrival at 2:00 p.m. Morning times also change day to day this week starting Tuesday, so check each day.

## Week 10 — October 5–9

Times below are Coach's published MAV Football Weekly Schedule for October 5–9.

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
Not on Coach's schedule this week.

## After Week 10

Week 11 times will be posted when Coach publishes that schedule.

See the Games schedule for the Stony Point game — JV Thursday Oct 8 at 6:00 p.m. at Stony Point, freshmen Thursday Oct 8 at 5:30 p.m. at Maverick Stadium (home), varsity Senior Night Friday Oct 9 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Friday Oct 9.** Coach's schedule lists no freshman session that day.

## Week 10 — October 5–9

Times below are Coach's published MAV Football Weekly Schedule for October 5–9.

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
Not on Coach's schedule for freshmen.

### Saturday, Oct 10 – Sunday, Oct 11
Not on Coach's schedule this week.

## After Week 10

Week 11 times will be posted when Coach publishes that schedule.

See the Games schedule for the Stony Point game — freshmen Thursday Oct 8 at 5:30 p.m. at Maverick Stadium (home), JV Thursday Oct 8 at 6:00 p.m. at Stony Point, varsity Senior Night Friday Oct 9 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 10 — October 5–9%';
  if n <> 3 then raise exception 'expected 3 Week 10 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 9 —%' or body like '%Cedar Ridge%'
     or body like '%eligibility%');
  if n <> 0 then raise exception '% bodies still carry Week 9 text', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%No school Friday Oct 9%'
     and body like '%**6:25–8:15 a.m.** — On the field%'
     and body like '%**6:45 a.m.** — Arrival%'
     and body like '%**9:50 a.m.** — Arrival%'
     and body like '%**2:00 p.m.** — Second arrival%'
     and body like '%Varsity team dinner%'
     and body not like '%Flex out%';
  if n <> 2 then raise exception 'varsity/jv Week 10 body not as intended on both rows (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%No school Friday Oct 9%'
     and body like '%**9:35 a.m.** — Practice complete%'
     and body not like '%5:40 a.m.%'
     and body not like '%team dinner%'
     and body not like '%Breakfast%';
  if n <> 1 then raise exception 'freshman Week 10 body not as intended (%)', n; end if;

  -- Games stay out of the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 10.*$', '', 's') ~ '(5:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;
end $$;

commit;

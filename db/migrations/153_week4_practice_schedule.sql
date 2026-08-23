-- 153_week4_practice_schedule.sql
--
-- Week 4 (Aug 24-30) practice times, from Coach's published MAV FOOTBALL
-- WEEKLY SCHEDULE for August 24-30 2026. Jeremy sent the Word doc 2026-08-22.
-- Replaces the Week 3 (Aug 17-23) block in all three bodies.
--
-- ── P2/P6 IS COACH'S OWN NOTATION NOW, AND THE PAGE ADOPTS IT ──
-- Week 3's bodies named a specific period per day ("Practice is during Period
-- 2" on Wednesday, "Period 6" on Thursday) and that invited exactly the wrong
-- conclusion: a reader comparing the page against a coach message that said
-- "2nd period" thought one of them was wrong. They are the same class. McNeil
-- runs an every-other-day block (periods 1-4 one day, 5-8 the next) and
-- athletics sits in the same slot daily - 2nd on a 1-4 day, 6th on a 5-8 day.
-- Coach now writes it "P2/P6" on every weekday at the same 11:15 start, which
-- settles it. The page uses P2/P6 and glosses it ONCE at the top. Do not put a
-- single period number back on a day.
--
-- ── TWO SESSIONS A DAY MON-WED ──
-- Varsity/JV have an early morning practice AND the P2/P6 on-field block on
-- Mon, Tue and Wed. That is not a duplicated row; both are listed on purpose.
-- Thu and Fri are "NO EARLY PRACTICE" and have the P2/P6 block only.
--
-- ── DELIBERATE LOSSES, both correct ──
-- 1. The picture-day photo-ordering pointer (migration 150) lived in the Friday
--    Aug 21 block and goes away with Week 3. Picture day has passed. The
--    ordering button itself is unaffected - it lives on the event
--    (/events/picture-day-2026, migration 149) and is still reachable there.
-- 2. The scrimmage no-meals warning (migration 152) lived in the Thursday
--    Aug 20 block and also goes away. This is REQUIRED, not incidental: Aug 27
--    and Aug 28 are GAMES, not scrimmages, and meals ARE provided for games.
--    Leaving that line in place would have been actively wrong. Coach lists a
--    Thursday TEAM DINNER instead.
--
-- Freshmen have no Saturday or Sunday entry in Coach's doc - the varsity
-- "ATHLETES - NO SCHEDULED ACTIVITIES" row spans the width. Recorded as no
-- scheduled activities rather than left blank, so the page does not read as
-- though times are missing.
--
-- Whole-body replacement rather than surgical edits: every day changed, and a
-- chain of replace() calls against a body this size is how a half-applied
-- schedule happens. Guarded on the body still being Week 3, so a re-run is a
-- no-op instead of clobbering Week 5 later.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.

begin;

-- Varsity and JV practice together and share one set of times.
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

Week 5 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27'
  and team_level in ('varsity', 'jv')
  and body like '%## Week 3 — August 17–23%';

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

Week 5 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27'
  and team_level = 'freshman'
  and body like '%## Week 3 — August 17–23%';

-- All three moved, none left on Week 3, and the stale blocks are gone.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and active and body like '%## Week 4 — August 24–30%';
  if n <> 3 then
    raise exception 'expected 3 bodies on Week 4, found %', n;
  end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 3%';
  if n <> 0 then
    raise exception '% bodies still mention Week 3', n;
  end if;

  -- Aug 27/28 are games, not scrimmages: the no-meals line must NOT survive.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Meals are not provided for scrimmages%';
  if n <> 0 then
    raise exception 'the scrimmage no-meals warning survived into Week 4 in % bodies', n;
  end if;

  -- No day may name a bare single period again.
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and (body like '%during Period 2%' or body like '%during Period 6%');
  if n <> 0 then
    raise exception '% bodies name a single period instead of P2/P6', n;
  end if;

  -- Every body must carry all seven days.
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and body like '%### Monday, Aug 24%'  and body like '%### Tuesday, Aug 25%'
     and body like '%### Wednesday, Aug 26%' and body like '%### Thursday, Aug 27%'
     and body like '%### Friday, Aug 28%' and body like '%### Saturday, Aug 29%'
     and body like '%### Sunday, Aug 30%';
  if n <> 3 then
    raise exception 'only % of 3 bodies carry all seven days', n;
  end if;
end $$;

commit;

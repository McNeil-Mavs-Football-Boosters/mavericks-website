-- 202_week8_practice_schedule.sql
--
-- Week 8 (Sep 21 - Sep 25) practice times, from Coach's published MAV FOOTBALL
-- WEEKLY SCHEDULE for September 21-25 2026 ("ONE MAV NATION"). Jeremy sent a
-- photo of the doc on Coach's screen 2026-09-18. Replaces the Week 6 block in
-- all three bodies.
--
-- ⚠️ WEEK 7 (SEP 14-20) WAS NEVER POSTED. No Week 7 weekly schedule reached
-- this repo (198/199 that week were a broadcast link and a kickoff time), so
-- the practice pages have shown Week 6 since 2026-09-06 -- twelve days, five of
-- them a week the page did not describe. Nothing to do about it now except say
-- so; the guard below therefore expects the bodies to still be on Week 6.
--
-- Conventions from 153/172/181 kept without restating: Coach's P2/P6 notation
-- is glossed once at the top; the whole body is replaced, guarded on the body
-- still being the previous week so a re-run is a no-op; GAMES DO NOT GO IN THE
-- DAY SECTIONS -- they live in `games` and the closing block points at the
-- Games schedule.
--
-- ── WHAT CHANGED FROM WEEK 6, so a reader can trust the diff ──
-- 1. 🚨 GAME WEEK IS A DAY EARLY. JV and freshmen play WEDNESDAY Sep 23 and
--    varsity plays THURSDAY Sep 24 (7:00 p.m., Kelly Reeves Athletic Complex).
--    `games` already has all three on those days (057 seed). Because every
--    other week has been Thu/Fri, both bodies carry a one-line ⚠️ pointer at the
--    top -- a pointer to the Games schedule, not a copy of the game data, which
--    is the 181 line.
-- 2. Coach's doc writes "JV GAME / Time TBA - Location TBA" and "FRESHMAN GAME
--    / Time TBA - Location TBA" on Wednesday. Jeremy: "TBD on JV and freshman
--    game times though." Migration 203 sets those two rows to result_status
--    'tbd', which is what the pointer text here relies on.
-- 3. Labor Day callout and the "Labor Day practice" heading are gone -- it is
--    past (172's rule was "while it is still ahead of us").
-- 4. Varsity/JV early practice is now 5:40 / 6:00 / 6:05-8:10 on BOTH Tue and
--    Wed (Week 6 had 5:45/6:00/8:10 Tue and 6:15/6:30/8:15 Wed). Monday is
--    6:40 / 7:00 / 7:25 / 10:15, the same shape as the Labor Day Monday.
-- 5. "Flex out" is now written by Coach three ways: "10:45 a.m. Flex out for
--    film" (Tue/Wed), "10:45 a.m. Varsity & JV flex out" (Thu/Fri), and a
--    footer "Athletes assigned to flex must report at 10:45 a.m." Still NOT
--    glossed (followups.md); the footer sentence is Coach's own and is quoted
--    at the top as the closest thing to a definition he has given.
-- 6. Coach's doc covers Monday-Friday only. No weekend rows exist on it, so the
--    bodies say "not on Coach's schedule this week" rather than inventing
--    "no scheduled activities" -- absence of a row is not evidence either way.
-- 7. Team dinner: the varsity team dinner before Lake Travis is WEDNESDAY Sep 23
--    (lib/team-dinners.ts, the club's own program, 6:00-7:30 p.m. on campus).
--    Week 6 wrote "time to be announced" and followups.md flags that the two
--    surfaces disagreed. The club runs the dinner, so the club's own slot is
--    the source here; it is one line on Wednesday in the varsity/JV body.
-- 8. Freshmen: Thursday is film / weights / breakfast (no practice line);
--    Friday is a 45-minute special teams walk-through. Transcribed as written.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 202_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 6 — September 7–13%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 6, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **Games are a day early this week.** JV plays **Wednesday Sep 23** and varsity plays **Thursday Sep 24**. See the Games schedule for times and locations.

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
- **5:40 a.m.** — Arrival
- **6:00 a.m.** — Ready on the field
- **6:05–8:10 a.m.** — Practice
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

See the Games schedule for the Lake Travis game — JV and freshmen Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **The freshman game is Wednesday this week** (Sep 23), not Thursday. Kickoff time to be announced — see the Games schedule.

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

See the Games schedule for the Lake Travis game — freshmen and JV Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 8 — September 21–25%';
  if n <> 3 then raise exception 'expected 3 Week 8 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 6%' or body like '%Labor Day%' or body like '%Sep 7%');
  if n <> 0 then raise exception '% bodies still carry Week 6 / Labor Day text', n; end if;

  -- Varsity/JV: Monday 6:40/7:00/7:25/10:15 and the 5:40 early days, on both rows.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%**6:40 a.m.** — Arrival%'
     and body like '%**10:15 a.m.** — Practice complete%'
     and body like '%**5:40 a.m.** — Arrival%'
     and body like '%**6:05–8:10 a.m.** — Practice%'
     and body like '%Varsity team dinner%';
  if n <> 2 then raise exception 'varsity/jv Week 8 times not set on both rows (%)', n; end if;

  -- Freshmen: 9:00/9:15/11:00 Monday, and must NOT have picked up the varsity pair.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**9:00 a.m.** — Arrival%'
     and body like '%**11:00 a.m.** — Practice complete%'
     and body like '%Special teams walk-through%'
     and body not like '%6:40 a.m.%'
     and body not like '%team dinner%';
  if n <> 1 then raise exception 'freshman Week 8 body not as intended (%)', n; end if;

  -- Week 6's early-practice times are gone (5:45 / 6:15 / 6:30 / 8:15), and so is 11:15.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and (body like '%5:45 a.m.%' or body like '%6:15 a.m.%' or body like '%8:15 a.m.** — Practice ends%' or body like '%11:15%');
  if n <> 0 then raise exception '% bodies still carry Week 6 early-practice times', n; end if;

  -- Games stay out of the day sections: no kickoff time or venue inside a "### " day
  -- except via the closing "See the Games schedule" pointer.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 8.*$', '', 's') like '%7:00 p.m.%';
  if n <> 0 then raise exception 'a varsity kickoff leaked into a day section'; end if;
end $$;

commit;

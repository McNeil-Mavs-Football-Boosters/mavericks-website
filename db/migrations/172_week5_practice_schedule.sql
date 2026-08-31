-- 172_week5_practice_schedule.sql
--
-- Week 5 (Aug 31 - Sep 6) practice times, from Coach's published MAV FOOTBALL
-- WEEKLY SCHEDULE for August 31-September 6 2026. Jeremy sent the doc 2026-08-31.
-- Replaces the Week 4 (Aug 24-30) block in all three bodies.
--
-- Same shape as 153, and its conventions are kept without restating them:
-- P2/P6 stays Coach's notation and is glossed once at the top; two sessions a
-- day Mon-Wed for varsity/JV; freshmen get explicit "no scheduled activities"
-- weekend rows rather than blanks so the page cannot read as missing data.
--
-- ── WHAT ACTUALLY CHANGED FROM WEEK 4, so a reader can trust the diff ──
-- 1. WEDNESDAY MOVED FIFTEEN MINUTES EARLIER for varsity/JV: arrival 6:30 ->
--    6:15, on the field 6:45 -> 6:30. Practice still ends 8:15. Mon/Tue are
--    unchanged (5:45 / 6:00-6:20 meetings / 6:25, and 5:45 / 6:00).
-- 2. Thursday gains a JV game and Friday a varsity game, but per the standing
--    convention THE PRACTICE BODY DOES NOT LIST GAMES -- they live in `games`
--    and are reached from the Games schedule. Week 4 did the same with the Bowie
--    games. The "After Week 5" block points at them instead.
-- 3. Freshmen are UNCHANGED from Week 4, every day. Transcribed in full anyway
--    rather than left alone: the body is replaced whole (see below), and a
--    reader comparing the page to Coach's doc should find every day present.
--
-- ── 🚨 LABOR DAY: THERE IS PRACTICE MONDAY SEPT 7 ──
-- Coach put "REMINDER: LABOR DAY PRACTICE MONDAY, SEPT. 7" in the Monday cell of
-- a week that ENDS Sept 6, so it is the one line on this doc that concerns a day
-- the schedule does not cover. It is also the single most likely thing for a
-- family to get wrong, because the default assumption for a school holiday is
-- that there is nothing. It is therefore stated TWICE on purpose -- once up top
-- where it cannot be missed and once in "After Week 5" -- and it must survive
-- into the Week 6 body when that lands. Times for it are not published yet, and
-- none are invented here.
--
-- Whole-body replacement, guarded on the body still being Week 4, so a re-run is
-- a no-op rather than clobbering a later week. Same reasoning as 153.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 172_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 4 — August 24–30%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 4, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together. **Be on time to class.**

🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week's schedule.

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

**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.

See the Games schedule for Game 2 vs Lake Belton — freshmen and JV Thursday Sep 3, varsity Friday Sep 4.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. **Be on time to class.**

🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week's schedule.

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

**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.

See the Games schedule for Game 2 vs Lake Belton — freshmen and JV Thursday Sep 3, varsity Friday Sep 4.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 5 — August 31–September 6%';
  if n <> 3 then raise exception 'expected 3 Week 5 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 4%';
  if n <> 0 then raise exception '% bodies still mention Week 4', n; end if;

  -- The Labor Day line is the one that must not be lost in a paste.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Labor Day%Sept 7%';
  if n <> 3 then raise exception 'Labor Day reminder missing from % bodies', 3 - n; end if;
end $$;

commit;

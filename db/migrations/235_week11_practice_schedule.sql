-- 235_week11_practice_schedule.sql
--
-- Week 11 (Oct 12-16, Westlake week) practice times, from Coach's published
-- MAV FOOTBALL WEEKLY SCHEDULE for October 12-16 2026 ("ONE MAV NATION").
-- Jeremy sent a photo 2026-10-12: "update this week's schedule". Replaces the
-- Week 10 block and 229's provisional Monday block in all three bodies.
--
-- Conventions from 153/172/181/202/218/226 kept: Period 2/6 glossed once at
-- the top; whole body replaced, guarded on the body still being Week 10 so a
-- re-run is a no-op; games live in `games` and only the closing block points
-- at them.
--
-- ── WHAT CHANGED FROM WEEK 10 / 229 ──
-- 1. Monday Oct 12 (no school, PD day) is now Coach's full sheet, not his
--    10/6 post: varsity/JV 6:45 arrival, 7:00 varsity meetings + JV on the
--    field, 7:25 varsity on the field, 8:45 practice complete, 8:55-10:00
--    varsity weights. Freshmen done at 11:00 (229 had 10:50 from the post;
--    the sheet outranks the post).
-- 2. Varsity/JV: Tue 6:15 / 6:30-8:10, Wed 6:45 / 7:00-8:10, Thu and Fri no
--    morning practice; Period 2/6 10:45 a.m.-12:10 p.m. Tue stretch and film,
--    Wed weights and film, Thu and Fri practice.
-- 3. Freshmen: Tue/Thu 8:00 / 8:25 / 9:35; NO practice Wed; Fri 8:30 arrival,
--    8:45 film and weights (no end time on the sheet, none invented).
-- 4. Varsity team dinner Thu Oct 15 6:00-7:30 p.m. (lib/team-dinners.ts), one
--    line on Thursday, same as 202/218/226.
-- 5. The sheet's footer REMINDER line is cut off in the photo; not carried.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
-- Rollback: 235_rollback.sql (captured from the live rows before apply).

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 10 — October 5–9%'
     and body like '%Monday, Oct 12: no school%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 10 + 229, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 12** (teacher professional development day). Practice is still on. **No morning practice Thursday or Friday** this week.

## Week 11 — October 12–16

Times below are Coach's published MAV Football Weekly Schedule for October 12–16.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Oct 12 — no school
- **6:45 a.m.** — Varsity and JV arrival
- **7:00 a.m.** — Varsity meetings; JV on the field
- **7:25 a.m.** — Varsity on the field
- **8:45 a.m.** — Practice complete
- **8:55–10:00 a.m.** — Varsity weights

### Tuesday, Oct 13
- **6:15 a.m.** — Arrival
- **6:30–8:10 a.m.** — Practice
- **10:45 a.m.–12:10 p.m.** — Period 2/6: stretch and film

### Wednesday, Oct 14
- **6:45 a.m.** — Arrival
- **7:00–8:10 a.m.** — Practice
- **10:45 a.m.–12:10 p.m.** — Period 2/6: weights and film

### Thursday, Oct 15 — JV game day
**No morning practice.**
- **10:45 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 16 — varsity game day
**No morning practice.**
- **10:45 a.m.–12:10 p.m.** — Period 2/6: practice

### Saturday, Oct 17 – Sunday, Oct 18
Not on Coach's schedule this week.

## After Week 11

Week 12 times will be posted when Coach publishes that schedule.

See the Games schedule for the Westlake game — JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home), freshmen Thursday Oct 15 at 5:00 and 6:30 p.m. at Chaparral Stadium, varsity Friday Oct 16 at 7:00 p.m. at Chaparral Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Monday Oct 12** (teacher professional development day). Practice is still on, starting later than usual. **No freshman practice Wednesday.**

## Week 11 — October 12–16

Times below are Coach's published MAV Football Weekly Schedule for October 12–16.

After practice, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Oct 12 — no school
- **9:15 a.m.** — Arrival
- **9:30 a.m.** — On the field
- **11:00 a.m.** — Practice complete

### Tuesday, Oct 13
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Wednesday, Oct 14
**No freshman practice.**

### Thursday, Oct 15 — game day
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:35 a.m.** — Practice complete

### Friday, Oct 16
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — Film and weights

### Saturday, Oct 17 – Sunday, Oct 18
Not on Coach's schedule this week.

## After Week 11

Week 12 times will be posted when Coach publishes that schedule.

See the Games schedule for the Westlake game — freshmen Thursday Oct 15 at 5:00 and 6:30 p.m. at Chaparral Stadium, JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home), varsity Friday Oct 16 at 7:00 p.m. at Chaparral Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 11 — October 12–16%';
  if n <> 3 then raise exception 'expected 3 Week 11 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 10 —%' or body like '%Stony Point%'
     or body like '%Senior Night%' or body like '%10:50%');
  if n <> 0 then raise exception '% bodies still carry Week 10 / 229 text', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%**7:25 a.m.** — Varsity on the field%'
     and body like '%**8:55–10:00 a.m.** — Varsity weights%'
     and body like '%**6:30–8:10 a.m.** — Practice%'
     and body like '%**7:00–8:10 a.m.** — Practice%'
     and body like '%Varsity team dinner%';
  if n <> 2 then raise exception 'varsity/jv Week 11 body not as intended on both rows (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**11:00 a.m.** — Practice complete%'
     and body like '%**No freshman practice.**%'
     and body like '%**8:45 a.m.** — Film and weights%'
     and body not like '%team dinner%';
  if n <> 1 then raise exception 'freshman Week 11 body not as intended (%)', n; end if;

  -- Games in the closing block must agree with `games`.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.opponent = 'Westlake High School'
     and ((g.team_level = 'jv' and g.game_date = timestamptz '2026-10-15 18:00 America/Chicago' and v.name = 'Maverick Stadium')
       or (g.team_level = 'freshman' and g.game_date in (timestamptz '2026-10-15 17:00 America/Chicago', timestamptz '2026-10-15 18:30 America/Chicago') and v.name = 'Chaparral Stadium')
       or (g.team_level = 'varsity' and g.game_date = timestamptz '2026-10-16 19:00 America/Chicago' and v.name = 'Chaparral Stadium'));
  if n <> 4 then raise exception 'Westlake games disagree with the closing block (%)', n; end if;

  -- Games stay out of the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 11.*$', '', 's') ~ '(5:00|6:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;
end $$;

commit;

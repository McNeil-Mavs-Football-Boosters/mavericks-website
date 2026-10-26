-- 257_week13_practice_westwood_round_rock_result.sql
--
-- Week 13 (Oct 26-30, Westwood week), from a photo of Coach's WEEKLY PRACTICE
-- SCHEDULE | OCTOBER 26-30, 2026 ("ONE MAV • ONE PURPOSE"). Jeremy 2026-10-26.
-- Plus the Round Rock (Homecoming) result.
--
-- ── PRACTICE BODIES (replaced whole, same conventions as 235/249) ──
--   V/JV: Mon 5:45 arrival, 6:00-6:20 meetings, 6:25 special teams / on field,
--   8:15 end; Tue 6:15 / 6:30 / 8:15; Wed 6:45 / 7:00 / 8:10; Thu and Fri no
--   morning practice, practice during athletic period. Athletic period notes:
--   Mon weights and film, Tue stretch and film, Wed weights and film. The sheet
--   prints NO athletic-period clock time this week, so none is stated (249's
--   11:00-12:10 was "this week" only).
--   Freshmen: Mon 8:00 / 8:25 on field / 9:30 end; Tue/Wed 8:00 / until 9:30;
--   Thu 8:00, morning routine as previous week; Fri 8:30 arrival, 8:45 film.
--   Footer carried: freshman Thu/Fri routines and Thursday game details are
--   subject to confirmation.
--   Varsity team dinner Thu Oct 29 6:00-7:30 (lib/team-dinners.ts), one line.
--
-- ── GAMES ──
-- Sheet: JV Thu Oct 29 5:30 at McNeil (Home); Freshmen Thu Oct 29 TBA / TBA;
-- Varsity Fri Oct 30 7:00 at Kelly Reeves. `games` had JV 6:00 from the seed;
-- doc outranks seed (120/219). Freshman Green row (6:30 at Westwood Warrior Bowl,
-- seed) is LEFT ALONE: the sheet says TBA, not a different time, and the closing
-- block says so rather than quoting the seed. Varsity matches. Hidden Blue
-- freshman row untouched (225/237).
--
-- Round Rock, Fri Oct 23 (Homecoming): varsity LOST 7-49 (Jeremy 2026-10-26:
-- "Team lost friday night 49-7"; our_score = 7). No broadcast rows exist for
-- Round Rock (checked live 10/26), so nothing to retire.
--
-- NOT TOUCHED: lib/fresh-jv-meals.ts Oct 29 pickup (3:00-5:00) vs the JV kickoff
-- moving 6:00 -> 5:30. Flagged to Jeremy, same as 249. Print View PDF goes to r7
-- in 258.
--
-- DB-ONLY, NO DEPLOY. Rollback: 257_rollback.sql (captured from the live rows).

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 12 — October 19–23%';
  if n <> 3 then raise exception 'expected 3 bodies on Week 12, found % (already updated?)', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.opponent = 'Westwood High School' and g.result_status = 'scheduled'
     and ((g.team_level = 'jv' and g.game_date = timestamptz '2026-10-29 18:00 America/Chicago' and v.name = 'Maverick Stadium')
       or (g.team_level = 'varsity' and g.game_date = timestamptz '2026-10-30 19:00 America/Chicago' and v.name = 'Kelly Reeves Athletic Complex'));
  if n <> 2 then raise exception 'Westwood games not as seeded (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity' and opponent = 'Round Rock High School'
     and result_status = 'scheduled' and game_date = timestamptz '2026-10-23 19:00 America/Chicago';
  if n <> 1 then raise exception 'Round Rock varsity not scheduled as expected (%)', n; end if;
end $$;

-- Round Rock
update games set result_status = 'final', our_score = 7, their_score = 49, updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and opponent = 'Round Rock High School'
   and game_date = timestamptz '2026-10-23 19:00 America/Chicago';

-- Westwood
update games set game_date = timestamptz '2026-10-29 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and opponent = 'Westwood High School'
   and game_date = timestamptz '2026-10-29 18:00 America/Chicago';

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **Monday starts early: 5:45 a.m. arrival.** **No morning practice Thursday or Friday** this week.

## Week 13 — October 26–30

Times below are Coach's published Weekly Practice Schedule for October 26–30.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

### Monday, Oct 26
- **5:45 a.m.** — Arrival
- **6:00–6:20 a.m.** — Meetings
- **6:25 a.m.** — Special teams / on the field
- **8:15 a.m.** — Practice ends
- **Period 2/6** — Weights and film

### Tuesday, Oct 27
- **6:15 a.m.** — Arrival
- **6:30 a.m.** — On the field
- **8:15 a.m.** — Practice ends
- **Period 2/6** — Stretch and film

### Wednesday, Oct 28
- **6:45 a.m.** — Arrival
- **7:00 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- **Period 2/6** — Weights and film

### Thursday, Oct 29 — JV game day
**No morning practice.**
- **Period 2/6** — Practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 30 — varsity game day
**No morning practice.**
- **Period 2/6** — Practice

### Saturday, Oct 31 – Sunday, Nov 1
Not on Coach's schedule this week.

**Reminder from Coach:** arrive on time and be ready to begin at the scheduled start.

## After Week 13

Week 14 times will be posted when Coach publishes that schedule.

See the Games schedule for the Westwood game — JV Thursday Oct 29 at 5:30 p.m. at Maverick Stadium (home), varsity Friday Oct 30 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

## Week 13 — October 26–30

Times below are Coach's published Weekly Practice Schedule for October 26–30.

After practice, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Oct 26
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:30 a.m.** — Morning practice ends

### Tuesday, Oct 27
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice ends

### Wednesday, Oct 28
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice ends

### Thursday, Oct 29 — game day
- **8:00 a.m.** — Arrival, same morning routine as last week

### Friday, Oct 30
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — Film

### Saturday, Oct 31 – Sunday, Nov 1
Not on Coach's schedule this week.

**Reminder from Coach:** arrive on time and be ready to begin at the scheduled start. Thursday and Friday routines are subject to confirmation.

## After Week 13

Week 14 times will be posted when Coach publishes that schedule.

The freshman game Thursday Oct 29 vs Westwood is listed by Coach as **time and location TBA**. Check the Games schedule before Thursday.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 13 — October 26–30%';
  if n <> 3 then raise exception 'expected 3 Week 13 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 12 —%' or body like '%Round Rock%'
     or body like '%11:00 a.m.%' or body like '%Homecoming%');
  if n <> 0 then raise exception '% bodies still carry Week 12 text', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%**5:45 a.m.** — Arrival%'
     and body like '%**6:00–6:20 a.m.** — Meetings%'
     and body like '%**8:10 a.m.** — Practice ends%'
     and body like '%Stretch and film%'
     and body like '%Varsity team dinner%';
  if n <> 2 then raise exception 'varsity/jv Week 13 body not as intended on both rows (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**8:25 a.m.** — On the field%'
     and body like '%**8:45 a.m.** — Film%'
     and body like '%time and location TBA%'
     and body not like '%team dinner%';
  if n <> 1 then raise exception 'freshman Week 13 body not as intended (%)', n; end if;

  -- Closing block must agree with `games`.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.opponent = 'Westwood High School'
     and ((g.team_level = 'jv' and g.game_date = timestamptz '2026-10-29 17:30 America/Chicago' and v.name = 'Maverick Stadium')
       or (g.team_level = 'varsity' and g.game_date = timestamptz '2026-10-30 19:00 America/Chicago' and v.name = 'Kelly Reeves Athletic Complex'));
  if n <> 2 then raise exception 'Westwood games disagree with the closing block (%)', n; end if;

  -- Games stay out of the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 13.*$', '', 's') ~ '(5:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity' and opponent = 'Round Rock High School'
     and result_status = 'final' and our_score = 7 and their_score = 49;
  if n <> 1 then raise exception 'Round Rock result not as intended (%)', n; end if;
end $$;

commit;

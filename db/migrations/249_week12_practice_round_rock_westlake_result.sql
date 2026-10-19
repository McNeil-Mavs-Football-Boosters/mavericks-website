-- 249_week12_practice_round_rock_westlake_result.sql
--
-- Week 12 (Oct 19-23, Round Rock / Homecoming week), from a photo of Coach's
-- MAV FOOTBALL WEEKLY SCHEDULE for October 19-23 2026 ("ONE MAV NATION").
-- Jeremy 2026-10-19: "update schedule for this week". Plus the Westlake result
-- and the Westlake sub-varsity changes 246 meant to make.
--
-- ── PRACTICE BODIES (replaced whole, same conventions as 235) ──
-- Replaces Week 11 and 248's provisional Week 12 Monday block. The sheet
-- outranks 248 (Jeremy's message): V/JV Monday practice runs 7:45-11:00
-- ("Practice / team activities"), not 8:00-11:00; freshmen arrive 9:45 for
-- 10:00-12:00 (248 had no arrival time).
--   V/JV: Tue 6:15 / 6:30-8:15, Wed 6:45 / 7:00-8:15, Thu and Fri no morning
--   practice ("PERIOD 2/6 — PRACTICE ONLY"). Period 2/6 is now 11:00-12:10
--   (was 10:45). Footer REMINDER carried: V/JV ready for athletic-period
--   activities at 11:00.
--   Freshmen: Tue/Wed/Thu 8:00 / 9:30 complete, Fri 8:25 / 9:30.
--   Varsity team dinner Thu Oct 22 6:00-7:30 (lib/team-dinners.ts), one line.
--
-- ── GAMES ──
-- Sheet: JV GAME 5:30 at Round Rock High School; FRESHMAN GAME 5:30 at McNeil
-- High School; VARSITY GAME 7:00 Kelley Reeves (Homecoming). `games` had JV
-- 6:00 and freshman Green 6:30 from the seed. Doc outranks seed (120/219), and
-- earlier is the stranding direction. Venues unchanged; varsity matches.
-- Hidden Blue freshman row untouched (225/237).
--
-- Westlake, Fri Oct 16: varsity LOST 6-70 (Jeremy 2026-10-19: "varsity lost
-- 70-6", theirs-first; our_score = 6). Final retires the 247 broadcast links
-- (keep_after_final = false, asserted).
--
-- ⚠️ 246 NEVER APPLIED LIVE. It was written after 248 and its last guard strips
-- the body from "## After Week 11", a heading 248 had already removed, so the
-- Westlake closing pointer's "6:00 p.m." tripped "kickoff leaked" and the whole
-- transaction rolled back (re-confirmed 2026-10-19, rolled back cleanly again).
-- Its two game changes (Jeremy 2026-10-14, source Coach: JV Westlake cancelled,
-- freshman Green 6:30 -> 6:00) land here instead; its practice-body edits are
-- moot because these bodies replace Week 11. 246 stays in apply_all (it runs
-- clean in order on a rebuild).
--
-- NOT TOUCHED: lib/fresh-jv-meals.ts Oct 22 pickup (3:00-5:00) — flagged to
-- Jeremy, kickoffs moved 30-60 min earlier; Print View PDF goes to r6 in 250.
--
-- DB-ONLY, NO DEPLOY. Rollback: 249_rollback.sql (captured from the live rows).

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 11 — October 12–16%'
     and body like '%## Week 12 — Monday, October 19%';
  if n <> 3 then raise exception 'expected 3 bodies on Week 11 + 248, found % (already updated?)', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.opponent = 'Round Rock High School' and g.result_status = 'scheduled'
     and ((g.team_level = 'jv' and g.game_date = timestamptz '2026-10-22 18:00 America/Chicago' and v.name = 'Round Rock High School Dragon Stadium')
       or (g.team_level = 'freshman' and g.team_designation = 'Green' and g.game_date = timestamptz '2026-10-22 18:30 America/Chicago' and v.name = 'Maverick Stadium')
       or (g.team_level = 'varsity' and g.game_date = timestamptz '2026-10-23 19:00 America/Chicago' and v.name = 'Kelly Reeves Athletic Complex'));
  if n <> 3 then raise exception 'Round Rock games not as seeded (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Westlake High School' and result_status = 'scheduled'
     and ((team_level = 'varsity' and game_date = timestamptz '2026-10-16 19:00 America/Chicago')
       or (team_level = 'jv' and game_date = timestamptz '2026-10-15 18:00 America/Chicago')
       or (team_level = 'freshman' and team_designation = 'Green' and game_date = timestamptz '2026-10-15 18:30 America/Chicago'));
  if n <> 3 then raise exception 'Westlake games not as expected (%)', n; end if;
end $$;

-- Westlake
update games set result_status = 'final', our_score = 6, their_score = 70, updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-16 19:00 America/Chicago';
update games set result_status = 'cancelled', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago';
update games set game_date = timestamptz '2026-10-15 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:30 America/Chicago';

-- Round Rock
update games set game_date = timestamptz '2026-10-22 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and opponent = 'Round Rock High School'
   and game_date = timestamptz '2026-10-22 18:00 America/Chicago';
update games set game_date = timestamptz '2026-10-22 17:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green' and opponent = 'Round Rock High School'
   and game_date = timestamptz '2026-10-22 18:30 America/Chicago';

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 19.** Practice is still on, starting 7:45 a.m. **No morning practice Thursday or Friday** this week. Friday is Homecoming.

## Week 12 — October 19–23

Times below are Coach's published MAV Football Weekly Schedule for October 19–23.

**Period 2/6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way. This week it runs **11:00 a.m.–12:10 p.m.**

### Monday, Oct 19 — no school
- **7:45 a.m.** — Arrival
- **7:45–11:00 a.m.** — Practice and team activities

### Tuesday, Oct 20
- **6:15 a.m.** — Arrival
- **6:30–8:15 a.m.** — Morning practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Wednesday, Oct 21
- **6:45 a.m.** — Arrival
- **7:00–8:15 a.m.** — Practice
- **11:00 a.m.–12:10 p.m.** — Period 2/6: athletic period

### Thursday, Oct 22 — JV game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice
- **Varsity team dinner** — 6:00–7:30 p.m. on campus, the night before the varsity game (see Team Dinners)

### Friday, Oct 23 — Homecoming, varsity game day
**No morning practice.**
- **11:00 a.m.–12:10 p.m.** — Period 2/6: practice

### Saturday, Oct 24 – Sunday, Oct 25
Not on Coach's schedule this week.

**Reminder from Coach:** arrive on time, dressed and ready. Varsity and JV athletes should be ready for athletic-period activities at 11:00 a.m.

## After Week 12

Week 13 times will be posted when Coach publishes that schedule.

See the Games schedule for the Round Rock game — JV Thursday Oct 22 at 5:30 p.m. at Round Rock High School (Dragon Stadium), freshmen Thursday Oct 22 at 5:30 p.m. at Maverick Stadium (home), varsity Homecoming Friday Oct 23 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Monday Oct 19.** Practice is still on, 10:00 a.m. to noon.

## Week 12 — October 19–23

Times below are Coach's published MAV Football Weekly Schedule for October 19–23.

After practice, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Oct 19 — no school
- **9:45 a.m.** — Arrival
- **10:00 a.m.–12:00 p.m.** — Practice

### Tuesday, Oct 20
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Wednesday, Oct 21
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Thursday, Oct 22 — game day
- **8:00 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Friday, Oct 23 — Homecoming
- **8:25 a.m.** — Arrival
- **9:30 a.m.** — Practice complete

### Saturday, Oct 24 – Sunday, Oct 25
Not on Coach's schedule this week.

## After Week 12

Week 13 times will be posted when Coach publishes that schedule.

See the Games schedule for the Round Rock game — freshmen Thursday Oct 22 at 5:30 p.m. at Maverick Stadium (home), JV Thursday Oct 22 at 5:30 p.m. at Round Rock High School (Dragon Stadium), varsity Homecoming Friday Oct 23 at 7:00 p.m. at Kelly Reeves Athletic Complex.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 12 — October 19–23%';
  if n <> 3 then raise exception 'expected 3 Week 12 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 11%' or body like '%Westlake%'
     or body like '%10:45%' or body like '%8:00–11:00%' or body like '%Week 12 — Monday%');
  if n <> 0 then raise exception '% bodies still carry Week 11 / 248 text', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%**7:45–11:00 a.m.** — Practice and team activities%'
     and body like '%**6:30–8:15 a.m.** — Morning practice%'
     and body like '%**7:00–8:15 a.m.** — Practice%'
     and body like '%Varsity team dinner%'
     and body like '%athletic-period activities at 11:00 a.m.%';
  if n <> 2 then raise exception 'varsity/jv Week 12 body not as intended on both rows (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**9:45 a.m.** — Arrival%'
     and body like '%**8:25 a.m.** — Arrival%'
     and body not like '%team dinner%';
  if n <> 1 then raise exception 'freshman Week 12 body not as intended (%)', n; end if;

  -- Closing block must agree with `games` (Green only for freshmen, 237).
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.opponent = 'Round Rock High School'
     and ((g.team_level = 'jv' and g.game_date = timestamptz '2026-10-22 17:30 America/Chicago' and v.name = 'Round Rock High School Dragon Stadium')
       or (g.team_level = 'freshman' and g.team_designation = 'Green' and g.game_date = timestamptz '2026-10-22 17:30 America/Chicago' and v.name = 'Maverick Stadium')
       or (g.team_level = 'varsity' and g.game_date = timestamptz '2026-10-23 19:00 America/Chicago' and v.name = 'Kelly Reeves Athletic Complex'));
  if n <> 3 then raise exception 'Round Rock games disagree with the closing block (%)', n; end if;

  -- Games stay out of the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 12.*$', '', 's') ~ '(5:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Westlake High School'
     and ((team_level = 'varsity' and result_status = 'final' and our_score = 6 and their_score = 70)
       or (team_level = 'jv' and result_status = 'cancelled' and our_score is null)
       or (team_level = 'freshman' and team_designation = 'Green' and game_date = timestamptz '2026-10-15 18:00 America/Chicago'));
  if n <> 3 then raise exception 'Westlake rows not as intended (%)', n; end if;

  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.opponent = 'Westlake High School' and b.keep_after_final;
  if n <> 0 then raise exception '% Westlake broadcast row(s) would survive the final', n; end if;
end $$;

commit;

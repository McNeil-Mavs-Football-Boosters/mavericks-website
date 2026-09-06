-- 181_week6_practice_schedule.sql
--
-- Week 6 (Sep 7 - Sep 13) practice times, from Coach's published MAV FOOTBALL
-- WEEKLY SCHEDULE for September 7-13 2026 ("ONE MAV NATION"). Jeremy sent the
-- doc 2026-09-06. Replaces the Week 5 (Aug 31 - Sep 6) block in all three
-- bodies, and with it the "After Week 5" Labor Day placeholder that 175 filled.
--
-- Conventions from 153/172 kept without restating: P2/P6 stays Coach's notation
-- and is glossed once at the top; freshmen get explicit "no scheduled
-- activities" weekend rows rather than blanks; whole-body replacement guarded on
-- the body still being Week 5 so a re-run is a no-op.
--
-- ── 🚨 THIS DOC SUPERSEDES 175's LABOR DAY TIMES, AND THEY ARE DIFFERENT ──
-- 175 published Labor Day from Coach's relayed text: varsity/JV "no later than
-- 6:30, practice begins 7:00"; freshmen "no later than 8:30, begins 9:00".
-- Coach's own graphic now gives it in the standard form and it does NOT match:
--
--   varsity/JV   6:40 arrival | 7:00-7:20 meetings | 7:25 on the field | 10:20 ends
--   freshmen     9:00 arrival | 9:25 on the field  | 11:20 ends
--
-- 175's closing note said exactly this: "If a later doc gives Labor Day in the
-- usual two-line form, that supersedes this." It does, so it does.
--
-- ⚠️ THE FRESHMAN ARRIVAL MOVED THIRTY MINUTES LATER (8:30 -> 9:00) and the
-- varsity arrival ten (6:30 -> 6:40). Neither strands anybody -- a family
-- working from last week's page arrives early, not late -- but the page said one
-- thing for six days and now says another, the day before the practice. Flagged
-- to Jeremy 2026-09-06; if it goes anywhere else it is SportsYou, not a
-- correction email.
--
-- ⚠️ Monday Sept 7 is now a real day INSIDE the week, so it moves out of the
-- "After Week 5" block and becomes a day heading. The 🚨 callout at the top
-- stays anyway -- 172 put it there twice on purpose because a school holiday
-- reads as "no practice" by default, and that risk is highest on the eve of it.
--
-- ── WHAT ACTUALLY CHANGED FROM WEEK 5, so a reader can trust the diff ──
-- 1. 🚨 P2/P6 STARTS AT 10:45, NOT 11:15 -- half an hour earlier, every day it
--    runs. This is the biggest change on the doc.
-- 2. Coach added a FLEX OUT line to every varsity/JV day that has P2/P6: "Be on
--    the field by 10:45 a.m." Transcribed as he wrote it. ⚠️ IT IS NOT GLOSSED.
--    P2/P6 gets a gloss because we know what it is; nobody here has confirmed
--    what "flex out" releases them from, and a guessed gloss on a schedule is
--    worse than Coach's own shorthand. If Coach explains it, gloss it then.
-- 3. 🚨 "Lunch after -- all C lunch" IS GONE, because it is not on this week's
--    doc. It rode on Mon/Tue/Wed in Weeks 4 and 5. It is NOT carried forward:
--    the block it hung off just moved thirty minutes earlier, which is exactly
--    the circumstance where a stale lunch assignment would be wrong. Absence of
--    a line is not evidence it still holds. If C lunch is in fact permanent,
--    Coach saying so puts it back.
-- 4. Varsity/JV Tue and Wed early practice are UNCHANGED (5:45/6:00/8:10 and
--    6:15/6:30/8:15). Thu and Fri are still "no early practice". Freshmen are
--    unchanged all week. Transcribed in full anyway -- the body is replaced
--    whole, and a reader comparing page to doc should find every day present.
-- 5. Thursday gains "JV GAME - TBA" and "FRESHMAN GAME - TBA"; Friday gains
--    "VARSITY GAME - 7:00 p.m. - Gupton Stadium vs. Rouse". Per the standing
--    convention GAMES DO NOT GO IN THE PRACTICE BODY -- they live in `games` and
--    are reached from the Games schedule, which the "After Week 6" block points
--    at. Weeks 4 and 5 did the same.
--
-- ⚠️ COACH SAYS "TBA" FOR BOTH THURSDAY GAMES AND THE SITE DOES NOT. `games`
-- carries JV Sep 10 at 6:00 p.m. and freshman Green at 6:30 p.m., both inherited
-- from the school's April export. The last two freshman games came in at 5:00,
-- so 6:30 is very likely the stale half of the school's two-team "Blue @ 5:00 /
-- Green @ 6:30" footnote that 148/155 retired. NOTHING IS CHANGED HERE: 155's
-- rule is that a freshman kickoff moves only on Coach's own graphic, and this
-- week's graphic declines to state one. Raised with Jeremy 2026-09-06.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 181_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 5 — August 31–September 6%';
  if n <> 3 then
    raise exception 'expected 3 bodies still on Week 5, found % (already updated?)', n;
  end if;
end $$;

-- Varsity and JV practice together and share one set of times.
update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together. **Be on time to class.**

🚨 **Labor Day, Monday Sept 7 — there IS practice.** Arrival **6:40 a.m.**, practice ends **10:20 a.m.** Full times under Monday below.

## Week 6 — September 7–13

Times below are Coach's published MAV Football Weekly Schedule for September 7–13.

**P2/P6** is the daily athletics period. McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next — same time slot either way.

⚠️ **P2/P6 starts at 10:45 a.m. this week — half an hour earlier than last week.** Coach added a "flex out" line to every day it runs.

### Monday, Sep 7 — Labor Day practice
- **6:40 a.m.** — Arrival
- **7:00–7:20 a.m.** — Meetings
- **7:25 a.m.** — On the field / stretch lines
- **10:20 a.m.** — Practice ends

### Tuesday, Sep 8
- **5:45 a.m.** — Arrival
- **6:00 a.m.** — On the field
- **8:10 a.m.** — Practice ends
- Shower / breakfast — do not be late to class
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:10 p.m.** — P2/P6, on the field

### Wednesday, Sep 9
- **6:15 a.m.** — Arrival
- **6:30 a.m.** — On the field
- **8:15 a.m.** — Practice ends
- Shower / get ready — do not be late to 1st period
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:10 p.m.** — P2/P6, on the field

### Thursday, Sep 10
**No early practice.**
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:15 p.m.** — P2/P6, on the field
- **Team dinner** — time to be announced

### Friday, Sep 11
**No early practice.**
- **Flex out** — be on the field by 10:45 a.m.
- **10:45 a.m.–12:00 p.m.** — P2/P6 — game day walkthrough / JV film

### Saturday, Sep 12
**Athletes: no scheduled activities.**
- **11:00 a.m.** — Coaches: scout input complete
- **4:00 p.m.** — Varsity grades sent to athletes

### Sunday, Sep 13
**Coaches workday.** Athletes: no scheduled activities.
- **11:30 a.m.** — Coordinators meeting
- **12:00 p.m.** — Special teams meeting
- Game preparation until completion

## After Week 6

Week 7 times will be posted when Coach publishes that schedule.

See the Games schedule for Game 3 vs Rouse — freshmen and JV Thursday Sep 10, varsity Friday Sep 11 at 7:00 p.m. at Gupton Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. **Be on time to class.**

🚨 **Labor Day, Monday Sept 7 — there IS practice.** Arrival **9:00 a.m.**, practice ends **11:20 a.m.** Full times under Monday below.

## Week 6 — September 7–13

Times below are Coach's published MAV Football Weekly Schedule for September 7–13.

After practice and breakfast, get to your **2nd/6th period** — McNeil runs an every-other-day block, so the same class is called 2nd period on one day and 6th on the next.

### Monday, Sep 7 — Labor Day practice
- **9:00 a.m.** — Arrival
- **9:25 a.m.** — On the field / stretch lines
- **11:20 a.m.** — Practice ends

### Tuesday, Sep 8
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Wednesday, Sep 9
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:45 a.m.** — Practice ends
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Thursday, Sep 10
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — On the field
- **9:30 a.m.** — Practice ends
- **9:45–10:05 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Friday, Sep 11
- **8:45 a.m.** — Arrival
- **9:00–10:00 a.m.** — Game film
- **10:00–10:20 a.m.** — Breakfast
- Shower — get to your 2nd/6th period

### Saturday, Sep 12
**Athletes: no scheduled activities.**

### Sunday, Sep 13
**Athletes: no scheduled activities.** Coaches workday.

## After Week 6

Week 7 times will be posted when Coach publishes that schedule.

See the Games schedule for Game 3 vs Rouse — freshmen and JV Thursday Sep 10, varsity Friday Sep 11 at 7:00 p.m. at Gupton Stadium.$body$,
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 6 — September 7–13%';
  if n <> 3 then raise exception 'expected 3 Week 6 bodies, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 5%';
  if n <> 0 then raise exception '% bodies still mention Week 5', n; end if;

  -- 172's rule: the Labor Day reminder must survive every rewrite while it is
  -- still ahead of us. It is now a day heading AND the top callout.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and body like '%Labor Day%Sept 7%'
     and body like '%### Monday, Sep 7 — Labor Day practice%';
  if n <> 3 then raise exception 'Labor Day missing from % bodies', 3 - n; end if;

  -- Varsity/JV carry the graphic's Labor Day times, and NOT 175's superseded pair.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%**6:40 a.m.** — Arrival%'
     and body like '%**7:25 a.m.** — On the field / stretch lines%'
     and body like '%**10:20 a.m.** — Practice ends%';
  if n <> 2 then raise exception 'varsity/jv Labor Day times not set on both rows (%)', n; end if;

  -- Freshmen carry 9:00/9:25/11:20 and must NOT have picked up the varsity pair.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%**9:00 a.m.** — Arrival%'
     and body like '%**11:20 a.m.** — Practice ends%';
  if n <> 1 then raise exception 'freshman Labor Day times not set (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman' and body like '%6:40 a.m.%';
  if n <> 0 then raise exception 'freshman body picked up the varsity Labor Day times'; end if;

  -- 175's placeholders and times are gone everywhere.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and (body like '%no later than%' or body like '%Practice begins%');
  if n <> 0 then raise exception '% bodies still carry 175 Labor Day wording', n; end if;

  -- P2/P6 moved to 10:45 on every varsity/JV day that has it; 11:15 is gone.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%11:15%';
  if n <> 0 then raise exception '% bodies still say 11:15 for P2/P6', n; end if;

  -- The C-lunch line is deliberately dropped, not accidentally retained.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%C lunch%';
  if n <> 0 then raise exception '% bodies still carry the stale C lunch line', n; end if;

  -- Games stay out of the practice bodies.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%### %' and body like '%Rouse%'
     and body not like '%See the Games schedule%';
  if n <> 0 then raise exception 'a game leaked into a practice body'; end if;
end $$;

commit;

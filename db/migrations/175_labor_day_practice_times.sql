-- 175_labor_day_practice_times.sql
--
-- Labor Day, Monday 9/7 now has real times. Coach, relayed by Jeremy 2026-08-31:
--
--   "Varsity/JV practice will begin at 7am. Players need to be here no later
--    than 6:30am. Freshman practice will begin at 9am. Players need to be here
--    no later than 8:30am."
--
-- 172 put the Labor Day reminder in all three bodies twice (top callout and the
-- "After Week 5" block) with "times will be posted" in both places, precisely so
-- there would be somewhere to put them. This fills both.
--
-- ── TRANSCRIBED IN COACH'S OWN TERMS, NOT TRANSLATED ──
-- The weekly-schedule bodies use "Arrival" then "On the field". Coach did not
-- write it that way here: he wrote "practice will begin" and "players need to be
-- here no later than". Those are NOT obviously the same pair -- "on the field at
-- 7:00" and "practice begins at 7:00" could differ by a warmup -- so the wording
-- follows him: "Arrival, no later than 6:30" and "Practice begins 7:00".
-- ⚠️ Do not normalise these into "On the field" to match the other days. If a
-- later doc gives Labor Day in the usual two-line form, that supersedes this.
--
-- ⚠️ NO END TIME IS STATED BECAUSE COACH DID NOT GIVE ONE. Every other day in
-- these bodies carries a "Practice ends" line, so its absence here will look
-- like an omission. It is not. Do not infer one from a normal Monday (8:10
-- varsity / 9:45 freshman) -- Labor Day is not a school day, so the whole shape
-- of the morning is different and there is no P2/P6 block to end before.
--
-- SEPT 7 IS OUTSIDE WEEK 5 (Aug 31 - Sep 6), which is why this lives in the
-- "After Week 5" block rather than as a day heading. When the Week 6 body lands
-- it will cover Sept 7 properly and this block gets replaced by the real week.
--
-- Targeted replaces rather than 172's whole-body rewrite: two strings change in
-- each body, and restating 100 lines to move two is its own risk. Guarded before
-- and asserted after, so a partial application cannot pass silently.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 175_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and body like '%## Week 5 — August 31–September 6%'
     and body like '%Times will be posted%';
  if n <> 3 then
    raise exception 'expected 3 Week 5 bodies still awaiting Labor Day times, found %', n;
  end if;
end $$;

-- Varsity + JV: 6:30 arrival, 7:00 start.
update practice_schedules
   set body = replace(
         replace(body,
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week''s schedule.',
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **6:30 a.m.**; practice begins at **7:00 a.m.**'),
         '**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.',
         '**Labor Day, Monday Sept 7 — there is practice.**
- **6:30 a.m.** — Arrival, no later than
- **7:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

-- Freshmen: 8:30 arrival, 9:00 start.
update practice_schedules
   set body = replace(
         replace(body,
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week''s schedule.',
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **8:30 a.m.**; practice begins at **9:00 a.m.**'),
         '**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.',
         '**Labor Day, Monday Sept 7 — there is practice.**
- **8:30 a.m.** — Arrival, no later than
- **9:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  -- Every "times will be posted" placeholder must be gone from all three bodies.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Times will be posted%';
  if n <> 0 then raise exception '% bodies still say "Times will be posted"', n; end if;

  -- Varsity and JV carry the 6:30/7:00 pair in BOTH places.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%6:30 a.m.%7:00 a.m.%'
     and body like '%no later than **6:30 a.m.**%';
  if n <> 2 then raise exception 'varsity/jv Labor Day times not set on both rows (%)', n; end if;

  -- Freshmen carry 8:30/9:00, and must NOT have picked up the varsity pair.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%no later than **8:30 a.m.**%'
     and body like '%**9:00 a.m.** — Practice begins%';
  if n <> 1 then raise exception 'freshman Labor Day times not set (%)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%no later than **6:30 a.m.**%';
  if n <> 0 then raise exception 'freshman body picked up the varsity Labor Day times'; end if;

  -- The Week 5 block itself must be untouched.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 5 — August 31–September 6%';
  if n <> 3 then raise exception 'Week 5 block damaged (%)', n; end if;
end $$;

commit;

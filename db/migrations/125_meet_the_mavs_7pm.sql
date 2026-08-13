-- 125_meet_the_mavs_7pm.sql
--
-- Meet the Mavs starts at 7:00 PM, not 6:00 PM. Jeremy 2026-08-13, the day
-- before the event.
--
-- ── Where the wrong time came from ──
-- 6:00 PM was the BOOSTER CLUB's call time (volunteers on site to set up), not
-- the time families arrive. Migration 108 had inherited 6:00-8:00 PM wholesale
-- from the 2025 event and flagged it at the time as "INHERITED ... not
-- independently confirmed for 2026". That flag was correct and this is it
-- coming due.
--
-- ⚠️ TWO PLACES, NOT ONE. The time is stored in the events row AND written into
-- the Friday block of all three practice bodies (migration 120). Migration 120's
-- note said the time was read from the events row "so the practice page and
-- /events cannot drift" — that was true at BUILD time only; the text is baked
-- into markdown, so it drifts the moment the event row changes. Both must move
-- together. If a future edit changes this event again, grep the practice bodies.
--
-- ⚠️ END TIME IS UNCHANGED AT 8:00 PM AND IS *NOT* CONFIRMED. Jeremy corrected
-- only the start. 8:00 PM is the same inherited-from-2025 value that produced
-- the wrong start, so it is suspect for the same reason — the event may well run
-- to 9:00. Only the corrected fact is applied here; the end is left alone rather
-- than shifted by an hour on a guess. Flagged to Jeremy.
--
-- The 6:00 PM booster call time is deliberately NOT published. It is an internal
-- volunteer instruction, and putting it on a family-facing page would send
-- families an hour early — which is the confusion this migration is fixing.

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug='meet-the-mavs-2026'
     and to_char(starts_at at time zone 'America/Chicago','HH24:MI') = '18:00';
  if n <> 1 then
    raise exception 'Expected Meet the Mavs starting 18:00 CT, found % matching row(s)', n;
  end if;
  select count(*) into n from practice_schedules
   where year='2026-27' and body like '%**6:00–8:00 p.m.** — Meet the Mavs%';
  if n <> 3 then
    raise exception 'Expected 3 practice bodies with the 6:00 Meet the Mavs line, found %', n;
  end if;
end $$;

update events
set starts_at = timestamptz '2026-08-14 19:00 America/Chicago'
where slug = 'meet-the-mavs-2026';

update practice_schedules
set body = replace(
      body,
      '- **6:00–8:00 p.m.** — Meet the Mavs',
      '- **7:00–8:00 p.m.** — Meet the Mavs')
where year = '2026-27'
  and body like '%**6:00–8:00 p.m.** — Meet the Mavs%';

commit;

-- Verification:
--   select to_char(starts_at at time zone 'America/Chicago','YYYY-MM-DD HH12:MI AM'),
--          to_char(ends_at   at time zone 'America/Chicago','HH12:MI AM')
--   from events where slug='meet-the-mavs-2026';        -> 2026-08-14 07:00 PM | 08:00 PM
--   select count(*) from practice_schedules
--    where year='2026-27' and body like '%6:00–8:00 p.m.%';   -> 0
--
-- /events and /schedule/practice/* read at request time; the homepage is ISR
-- revalidate=60. No deploy required.

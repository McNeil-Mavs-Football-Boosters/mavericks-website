-- 129_practice_week3_from_coach_doc.sql
--
-- Week 3 written from Coach's published "MAV FOOTBALL WEEKLY SCHEDULE,
-- August 17-23, 2026 - ONE MAV NATION" doc, which Jeremy sent 2026-08-16.
-- Replaces the Week 2 bodies (migration 120) and the tentative Aug 17-28 tail
-- that 077 seeded.
--
-- ── THE TENTATIVE TAIL WAS DROPPED, NOT CARRIED ──
-- 120 carried the "After Week 2 - tentative" list across verbatim. That list is
-- now demonstrably wrong for the school year: it had Mon Aug 17 at 6:30-10:00
-- (real: 7:00-10:15) and Wed Aug 19 at 6:20-8:15 (real: on the field 10:45 a.m.,
-- during Period 2). Once school starts, practice moves INSIDE the school day, so
-- the Aug 24-28 estimates in that tail - all early-morning windows inherited
-- from the 077 preseason grid - would publish a practice time no one will keep.
-- A parent reading "Mon Aug 24 - 6:00-8:15" would show up four hours early.
-- Replaced with a pointer to next week's doc plus the Games schedule, which is
-- real data. Restore the tail only if Coach publishes actual Week 4 times.
--
-- ⚠️ JV/THURSDAY AMBIGUITY - same call as migration 120, same reasoning.
-- The doc's two columns are UPPERCLASSMEN (SOPH/JR/SR) and FRESHMEN, so JV
-- shares the upperclassmen body. But Thursday's upperclassmen cell reads
-- "SCRIMMAGE - UPPERCLASSMEN 1ST & 2ND GROUP" at 7:00 p.m. while the freshmen
-- cell reads "FRESHMAN & JV SCRIMMAGE" at 5:30 p.m. Read literally, a JV athlete
-- practices Period 6 with the upperclassmen and then scrimmages at 5:30 with the
-- freshmen. JV therefore gets the 5:30 block, NOT 7:00 - publishing 7:00 would
-- put a JV family 90 minutes late. This matches how the Aug 13 Hendrickson
-- scrimmage is already seeded in `games` (JV 5:30, varsity 7:00, migration 078),
-- so the two surfaces agree.
--
-- Wednesday and Thursday upperclassmen cells give NO arrival time - only
-- "PERIOD 2" / "PERIOD 6", on the field 10:45, ends 12:00. Transcribed as
-- written; no arrival time was invented.
--
-- Saturday and Sunday are PLAYERS: OFF. The coaches' scouting/workday blocks in
-- those cells are staff-facing and are summarised in one line rather than
-- reprinted - the practice page is read by families.
--
-- Meet the Mavs (Fri Aug 14) leaves the bodies with Week 2. That closes the
-- drift risk the Status section flagged: the event time now lives only in the
-- `events` row.
--
-- Companion: migration 130 puts the Thursday scrimmage times from this same doc
-- onto the four Aug 20 Eastview `games` rows, which were seeded time-TBD.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Tuesday, Aug 18
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
**Practice is during Period 2.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 20
**Practice is during Period 6.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

**Scrimmage vs Eastview — upperclassmen 1st & 2nd group**
- **6:00 p.m.** — Arrival
- **6:25 p.m.** — On the field
- **7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **7:00 a.m.** — Arrival
- **8:00 a.m.** — Pictures complete
- Film during Period 2

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Tuesday, Aug 18
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
**Practice is during Period 2.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 20
**Practice is during Period 6.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

**Freshman & JV scrimmage vs Eastview**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **7:00 a.m.** — Arrival
- **8:00 a.m.** — Pictures complete
- Film during Period 2

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **9:00 a.m.** — Arrival
- **9:20 a.m.** — On the field
- **10:40 a.m.** — Practice ends

### Tuesday, Aug 18
- **9:00 a.m.** — Arrival
- **9:20 a.m.** — On the field
- **10:40 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:40 a.m.** — Practice ends

### Thursday, Aug 20
**Morning practice**
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:40 a.m.** — Practice ends

**Freshman & JV scrimmage vs Eastview**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **8:00 a.m.** — Arrival
- **9:15 a.m.** — Pictures complete
- Film after pictures, time permitting

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'freshman';

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 3 — August 17–23%';
  if n <> 3 then raise exception 'expected 3 week-3 bodies, got %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 2%' or body like '%Aug 10%'
                               or body like '%Aug 13%' or body like '%Aug 15%'
                               or body like '%Meet the Mavs%' or body like '%tentative%');
  if n <> 0 then raise exception 'stale week-2/tentative text left in % bodies', n; end if;

  -- Thursday scrimmage: varsity 7:00 p.m. only; JV and freshmen 5:30 p.m. only.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'varsity'
     and body like '%7:00 p.m.%' and body not like '%5:30 p.m.%';
  if n <> 1 then raise exception 'varsity thursday scrimmage time wrong'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('jv', 'freshman')
     and body like '%5:30 p.m.%' and body not like '%7:00 p.m.%';
  if n <> 2 then raise exception 'jv/freshman thursday scrimmage time wrong'; end if;

  -- Upperclassmen Wed/Thu are in-school-day; freshmen are not.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity', 'jv')
     and body like '%Period 2%' and body like '%Period 6%' and body like '%12:00 p.m.%';
  if n <> 2 then raise exception 'upperclassmen in-school-day blocks missing'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%9:40 a.m.%' and body not like '%Period%';
  if n <> 1 then raise exception 'freshman wed/thu block wrong'; end if;
end $$;

commit;

-- /schedule/practice/* reads at request time: live with no deploy.

-- 120_practice_week2_from_coach_doc.sql
--
-- Week 2 rewritten from Coach's actual "MAV FOOTBALL WEEKLY SCHEDULE,
-- August 10-15, 2026" doc, which Jeremy sent 2026-08-09. This CORRECTS
-- migration 118, which was built from a verbal relay the day before.
--
-- ── WHAT 118 GOT WRONG (all six, verified against the doc) ──
--   Upper Mon-Wed end   9:50      -> 10:00
--   Fresh Mon-Wed arrive 8:35     -> 8:30
--   Thursday            "See Games" placeholder -> full morning + scrimmage times
--   Friday              regular practice        -> WEIGHTS / CONDITIONING / FILM
--   Saturday upper      9:00-11:00              -> 7:00 / 7:25 / 10:30
--   Saturday freshmen   "No practice"           -> 9:30 / 9:55 / 10:45
--
-- Friday and Saturday were the two days 118 explicitly flagged as unconfirmed
-- because Coach had only given one set of times for "next week". Both were
-- wrong, and Friday was not even a practice. Established rule, reconfirmed:
-- treat Coach's weekly doc as authoritative over any verbal relay or seeded
-- preseason grid.
--
-- ⚠️ JV NOW DIFFERS FROM VARSITY ON THURSDAY — first time these two bodies have
-- diverged. Coach's doc has two columns, UPPERCLASSMEN (SOPH/JR/SR) and
-- FRESHMEN, so JV has always shared the upperclassmen body. But Thursday's
-- freshmen cell is labelled "FRESHMAN & JV SCRIMMAGE" at 5:30 p.m., while the
-- upperclassmen cell has a 7:00 p.m. scrimmage. Read literally, a JV athlete
-- does the 7:35 a.m. upperclassmen practice and then scrimmages at 5:30 with the
-- freshmen, NOT at 7:00.
-- This is an INFERENCE from a doc that is internally ambiguous (JV are sophomores
-- and so also sit inside the upperclassmen column). It is called out to Jeremy.
-- Publishing 7:00 for JV would have been the more dangerous guess: a JV family
-- reading it would arrive 90 minutes after their scrimmage started.
--
-- Meet the Mavs added to BOTH Friday blocks, marked mandatory, per Jeremy — it
-- doubles as a reminder. Time and venue taken from the events row seeded by
-- migration 108 (Fri Aug 14, 6:00-8:00 p.m., McNeil High School Stadium) rather
-- than retyped, so the practice page and /events cannot drift.
--
-- Bodies built by transforming the live rows; the Aug 17-28 tentative tail is
-- carried across verbatim. Assertions were scoped to the WEEK 2 SECTION — a
-- whole-body check for the stale "9:50" false-positives on the legitimate
-- "Aug 24 - 8:10-9:50" tentative entry.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Thursday, Aug 13
**Morning practice**
- **7:35 a.m.** — Arrival
- **8:00 a.m.** — On the field

**Scrimmage vs Hendrickson**
- **5:50 p.m.** — Arrival
- **6:30 p.m.** — Stretch lines begin on the field
- **7:00 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **8:15 a.m.** — Arrival
- **8:30 a.m.** — Weights / Conditioning / Film begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — Stretch lines begin on the field
- **10:30 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Thursday, Aug 13
**Morning practice**
- **7:35 a.m.** — Arrival
- **8:00 a.m.** — On the field

**Freshman & JV scrimmage**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **8:15 a.m.** — Arrival
- **8:30 a.m.** — Weights / Conditioning / Film begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — Stretch lines begin on the field
- **10:30 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Tuesday, Aug 11
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Wednesday, Aug 12
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Thursday, Aug 13
**No morning practice.**

**Freshman & JV scrimmage**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **7:15 a.m.** — Early arrival
- **7:30 a.m.** — Weights / Film / Conditioning begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **9:30 a.m.** — Arrival
- **9:55 a.m.** — On the field
- **10:45 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 9:00–11:00
- **Tue Aug 18** — 9:00–11:00
- **Wed Aug 19** — 8:10–9:45 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 8:00–10:15 · Picture day
- **Mon Aug 24** — 8:10–9:50
- **Tue Aug 25** — 8:10–9:50
- **Wed Aug 26** — 8:10–9:50
- **Thu Aug 27** — 8:45–9:50
- **Fri Aug 28** — 8:30–9:50 · Game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'freshman';

commit;

-- /schedule/practice/* reads at request time: live with no deploy.

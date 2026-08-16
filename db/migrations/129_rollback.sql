-- 129_rollback.sql — restores the Week 2 bodies (migration 120) exactly as
-- they were live on 2026-08-16 before Week 3 was published.

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

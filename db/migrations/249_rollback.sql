-- 249_rollback.sql
-- Restores the practice bodies (Week 11 + 248's Week 12 Monday block) byte-for-byte and the
-- Westlake/Round Rock games rows as they stood before 249. Generated from the live rows before apply.
begin;
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 12** (teacher professional development day). Practice is still on. **No morning practice Thursday or Friday** this week.

## Week 11 — October 12–16

Times below are Coach''s published MAV Football Weekly Schedule for October 12–16.

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
Not on Coach''s schedule this week.

## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **7:45 a.m.** — Varsity and JV arrival
- **8:00–11:00 a.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.

See the Games schedule for the Westlake game — JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home), freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule), varsity Friday Oct 16 at 7:00 p.m. at Chaparral Stadium.', updated_at = now() where year = '2026-27' and team_level = 'varsity';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. Varsity and JV practice together. **Be on time to class.**

⚠️ **No school Monday Oct 12** (teacher professional development day). Practice is still on. **No morning practice Thursday or Friday** this week.

## Week 11 — October 12–16

Times below are Coach''s published MAV Football Weekly Schedule for October 12–16.

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
Not on Coach''s schedule this week.

## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **7:45 a.m.** — Varsity and JV arrival
- **8:00–11:00 a.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.

See the Games schedule for the Westlake game — JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home), freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule), varsity Friday Oct 16 at 7:00 p.m. at Chaparral Stadium.', updated_at = now() where year = '2026-27' and team_level = 'jv';
update practice_schedules set body = 'Athletes must arrive on time and be dressed, prepared, and ready to begin at the listed start time. **Be on time to class.**

⚠️ **No school Monday Oct 12** (teacher professional development day). Practice is still on, starting later than usual. **No freshman practice Wednesday.**

## Week 11 — October 12–16

Times below are Coach''s published MAV Football Weekly Schedule for October 12–16.

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
Not on Coach''s schedule this week.

## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **10:00 a.m.–12:00 p.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.

See the Games schedule for the Westlake game — freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule), JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home), varsity Friday Oct 16 at 7:00 p.m. at Chaparral Stadium.', updated_at = now() where year = '2026-27' and team_level = 'freshman';
update games set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-16 19:00 America/Chicago';
update games set result_status = 'scheduled', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago';
update games set game_date = timestamptz '2026-10-15 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green' and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago';
update games set game_date = timestamptz '2026-10-22 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and opponent = 'Round Rock High School'
   and game_date = timestamptz '2026-10-22 17:30 America/Chicago';
update games set game_date = timestamptz '2026-10-22 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green' and opponent = 'Round Rock High School'
   and game_date = timestamptz '2026-10-22 17:30 America/Chicago';
commit;

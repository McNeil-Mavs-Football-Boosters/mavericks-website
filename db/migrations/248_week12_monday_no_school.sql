-- 248_week12_monday_no_school.sql
--
-- Monday Oct 19 is a no-school day. Jeremy 2026-10-16: "Monday practice
-- schedule varsity and JV will arrive at 7:45 start time 8:00 to 11:00.
-- Freshman 10:00 to 12:00." and "Monday is another day off so schedule is
-- different for them".
--
-- Week 11 stays on the page (it is still Friday, varsity plays tonight). The
-- "After Week 11" placeholder on all three bodies is replaced by a Week 12
-- Monday block; the rest of Week 12 waits for Coach's sheet, which will
-- replace the bodies whole as usual. Freshman has no separate arrival time
-- (none was given), so it lists the practice window only.
--
-- DB-ONLY, NO DEPLOY. Rollback: 248_rollback.sql (old bodies captured live).

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## After Week 11%Week 12 times will be posted when Coach publishes that schedule.%';
  if n <> 3 then raise exception 'expected 3 bodies with the After Week 11 placeholder, found % (already applied?)', n; end if;
end $$;

update practice_schedules
   set body = replace(body, $body$## After Week 11

Week 12 times will be posted when Coach publishes that schedule.
$body$, $body$## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **7:45 a.m.** — Varsity and JV arrival
- **8:00–11:00 a.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.
$body$), updated_at = now()
 where year = '2026-27' and team_level = 'varsity';

update practice_schedules
   set body = replace(body, $body$## After Week 11

Week 12 times will be posted when Coach publishes that schedule.
$body$, $body$## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **7:45 a.m.** — Varsity and JV arrival
- **8:00–11:00 a.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.
$body$), updated_at = now()
 where year = '2026-27' and team_level = 'jv';

update practice_schedules
   set body = replace(body, $body$## After Week 11

Week 12 times will be posted when Coach publishes that schedule.
$body$, $body$## Week 12 — Monday, October 19

⚠️ **No school Monday Oct 19.** Practice is still on, later than a normal school day.

### Monday, Oct 19 — no school
- **10:00 a.m.–12:00 p.m.** — Practice

The rest of Week 12 will be posted when Coach publishes that schedule.
$body$), updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules where year = '2026-27' and body like '%After Week 11%';
  if n <> 0 then raise exception '% bodies still carry the After Week 11 placeholder', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%### Monday, Oct 19 — no school
- **7:45 a.m.** — Varsity and JV arrival
- **8:00–11:00 a.m.** — Practice%';
  if n <> 2 then raise exception 'varsity/JV Monday Oct 19 block wrong (found %)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%### Monday, Oct 19 — no school
- **10:00 a.m.–12:00 p.m.** — Practice%';
  if n <> 1 then raise exception 'freshman Monday Oct 19 block wrong (found %)', n; end if;

  -- Week 11 is still intact on all three.
  select count(*) into n from practice_schedules where year = '2026-27' and body like '%## Week 11 — October 12–16%';
  if n <> 3 then raise exception 'Week 11 section missing on % bodies', 3 - n; end if;
end $$;

commit;

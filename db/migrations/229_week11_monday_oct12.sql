-- 229_week11_monday_oct12.sql
--
-- Coach Gardner's post 2026-10-06, relayed by Jeremy: Monday Oct 12 is a teacher
-- professional development day (no school), practice is on.
--   Varsity and JV: arrival 6:45 a.m., on the field 7:00, done at 10:00
--   Freshmen: arrival 9:15 a.m., on the field 9:30, done at 10:50
-- Added under "After Week 10" ahead of the full Week 11 graphic; the Week 10
-- bodies are otherwise untouched. Replace whole when Week 11 arrives.
-- DB-ONLY, NO DEPLOY. Rollback: 229_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 11 times will be posted when Coach publishes that schedule.%';
  if n <> 3 then raise exception 'expected 3 bodies with the Week 11 placeholder, found %', n; end if;
end $$;

update practice_schedules
set body = replace(body, 'Week 11 times will be posted when Coach publishes that schedule.',
$t$### Monday, Oct 12: no school (teacher professional development day)
Practice is still on.
- **6:45 a.m.**: Arrival
- **7:00 a.m.**: On the field
- **10:00 a.m.**: Done

The rest of Week 11 will be posted when Coach publishes that schedule.$t$),
    updated_at = now()
where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
set body = replace(body, 'Week 11 times will be posted when Coach publishes that schedule.',
$t$### Monday, Oct 12: no school (teacher professional development day)
Practice is still on.
- **9:15 a.m.**: Arrival
- **9:30 a.m.**: On the field
- **10:50 a.m.**: Done

The rest of Week 11 will be posted when Coach publishes that schedule.$t$),
    updated_at = now()
where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Monday, Oct 12: no school%';
  if n <> 3 then raise exception 'expected 3 bodies updated, found %', n; end if;
end $$;

commit;

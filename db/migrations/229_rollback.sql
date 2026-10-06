-- 229_rollback.sql: restores the Week 11 placeholder line in all three bodies.
begin;
update practice_schedules
set body = regexp_replace(body, '### Monday, Oct 12: no school.*?The rest of Week 11 will be posted when Coach publishes that schedule\.',
  'Week 11 times will be posted when Coach publishes that schedule.', 's'),
    updated_at = now()
where year = '2026-27' and body like '%Monday, Oct 12: no school%';
commit;

-- 125_rollback.sql — back to the (incorrect) 6:00 PM start.
begin;
update events set starts_at = timestamptz '2026-08-14 18:00 America/Chicago'
where slug='meet-the-mavs-2026';
update practice_schedules
set body = replace(body, '- **7:00–8:00 p.m.** — Meet the Mavs', '- **6:00–8:00 p.m.** — Meet the Mavs')
where year='2026-27' and body like '%**7:00–8:00 p.m.** — Meet the Mavs%';
commit;

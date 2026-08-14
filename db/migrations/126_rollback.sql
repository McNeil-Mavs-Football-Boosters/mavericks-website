-- 126_rollback.sql — back to 7:00 PM (i.e. re-applies migration 125).
begin;
update events set starts_at = timestamptz '2026-08-14 19:00 America/Chicago'
where slug='meet-the-mavs-2026';
update practice_schedules
set body = replace(body, '- **6:00–8:00 p.m.** — Meet the Mavs', '- **7:00–8:00 p.m.** — Meet the Mavs')
where year='2026-27' and body like '%**6:00–8:00 p.m.** — Meet the Mavs%';
commit;

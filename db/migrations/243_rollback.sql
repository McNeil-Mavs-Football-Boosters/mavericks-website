-- 243_rollback.sql: point the English flyer link back at the 241 object.
begin;
update events
   set description = replace(description, 'tunnel-stampede-2026-flyer-en-r2.jpg)', 'tunnel-stampede-2026-flyer-en.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';
commit;

-- 242_rollback.sql: point the Español flyer link back at the 241 object.
begin;
update events
   set description = replace(description, 'tunnel-stampede-2026-flyer-es-r2.jpg)', 'tunnel-stampede-2026-flyer-es.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';
commit;

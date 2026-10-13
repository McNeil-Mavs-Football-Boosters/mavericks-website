-- 245_rollback.sql: point both flyer links back at the r2 objects.
begin;
update events
   set description = replace(replace(description,
         'tunnel-stampede-2026-flyer-en-r3.jpg)', 'tunnel-stampede-2026-flyer-en-r2.jpg)'),
         'tunnel-stampede-2026-flyer-es-r3.jpg)', 'tunnel-stampede-2026-flyer-es-r2.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';
commit;

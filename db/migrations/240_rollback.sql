-- 240_rollback.sql: restore 239's close-date text.
begin;
update events
   set description = replace(description, 'closes Wednesday, October 21', 'closes Wednesday, October 22')
 where slug = 'homecoming-tunnel-stampede-2026';
commit;

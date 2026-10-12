-- 241_rollback.sql: drop the flyer links line.
begin;
update events
   set description = regexp_replace(description, E'\n\nFlyer: \\[English\\].*$', '')
 where slug = 'homecoming-tunnel-stampede-2026';
commit;

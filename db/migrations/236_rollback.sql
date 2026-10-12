-- 236_rollback.sql
begin;
delete from events where slug = 'homecoming-tunnel-stampede-2026';
commit;

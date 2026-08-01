-- 108_rollback.sql
begin;
delete from events where slug = 'meet-the-mavs-2026';
commit;

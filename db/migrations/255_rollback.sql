-- 255_rollback.sql
begin;
delete from events where slug = 'homecoming-shirt-preorder-2026';
commit;

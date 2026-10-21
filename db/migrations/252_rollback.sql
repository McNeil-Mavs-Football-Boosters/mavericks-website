-- 252_rollback.sql -- remove the trainer row 252 added (photo object stays in the bucket).
begin;
delete from coaches where year = '2026-27' and name = 'Maggie Florez-Cook' and role_category = 'trainer';
commit;

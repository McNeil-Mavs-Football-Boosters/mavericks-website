-- 128_rollback.sql
begin;
delete from sponsors where year='2026-27' and name in ('Kathy Sokolic, REALTOR®','Round Rock Express');
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=12 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
commit;

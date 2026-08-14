-- 127_rollback.sql — removes ATFCU and restores Blue's historical order.
begin;
delete from sponsors where year='2026-27' and name='Austin Telco Federal Credit Union';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';
commit;

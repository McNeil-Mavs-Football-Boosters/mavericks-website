-- 121_rollback.sql
begin;
delete from sponsors where year='2026-27' and name='Santiago''s Tex-Mex & Cantina';
commit;

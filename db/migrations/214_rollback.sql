-- 214_rollback.sql
begin;
update coaches set email = null, teaching_role = null, updated_at = now()
 where year = '2026-27' and active and name in ('Barrett Matthews','Nick Edwards','Thomas Umberger','Raleigh Texada');
update coaches set email = null, updated_at = now() where year = '2026-27' and active and name = 'Alexander Gillis';
update coaches set teaching_role = 'Special Education Teacher', updated_at = now() where year = '2026-27' and active and name = 'Reginal Debose';
commit;

-- 221_rollback.sql
begin;
delete from events where slug = 'whatakick-challenge-2026-10-01';
update games set notes = null, updated_at = now()
 where year = '2026-27' and team_level = 'jv' and notes = 'WhataKick Challenge at halftime';
commit;

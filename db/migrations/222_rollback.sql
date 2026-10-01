-- 222_rollback.sql
begin;
update events set description = replace(description, 'beginning at 4:55 PM', 'beginning at 5:25 PM'), updated_at = now()
 where slug = 'whatakick-challenge-2026-10-01';
commit;

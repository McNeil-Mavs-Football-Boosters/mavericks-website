-- 215_rollback.sql
--
-- Removes the Senior Night locker decorating event. The McNeil High School
-- venue row predates 215 and is not touched.

begin;

delete from events where slug = 'senior-night-locker-decorating-2026-10-08';

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'senior-night-locker-decorating-2026-10-08';
  if n <> 0 then raise exception 'event still present (%)', n; end if;
end $$;

commit;

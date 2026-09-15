-- 197_rollback.sql
--
-- Removes the Mavs and Moms Senior Photo Day event. The McNeil High School
-- venue row predates this migration and is left alone.

begin;

delete from events where slug = 'mavs-and-moms-senior-photo-day-2026';

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'mavs-and-moms-senior-photo-day-2026';
  if n <> 0 then raise exception 'rollback did not remove the event'; end if;
end $$;

commit;

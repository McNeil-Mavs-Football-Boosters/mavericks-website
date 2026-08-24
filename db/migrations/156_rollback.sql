-- 156_rollback.sql
--
-- Removes the Varsity Helmet Decal Night event. Safe to run: nothing references
-- events by id, and the row carries no uploaded asset (no cover image was used).

begin;

delete from events where slug = 'varsity-helmet-decal-night-2026';

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'varsity-helmet-decal-night-2026';
  if n <> 0 then raise exception 'decal night event still present'; end if;
end $$;

commit;

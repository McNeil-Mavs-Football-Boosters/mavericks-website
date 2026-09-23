-- 210_rollback.sql
--
-- Removes the three Oct/Nov spirit nights and the two venue rows 210 added.
-- The September spirit nights (192-194) are not touched.

begin;

delete from events
 where slug in ('spirit-night-pok-e-jos-2026-10-14',
                'spirit-night-raising-canes-2026-10-26',
                'spirit-night-raising-canes-2026-11-09');

delete from venues
 where name in ('Pok-e-Jo''s Smokehouse (Parmer)', 'Raising Cane''s Chicken Fingers (N I-35)')
   and not exists (select 1 from events e where e.venue_id = venues.id);

do $$
declare n int;
begin
  select count(*) into n from events where slug like 'spirit-night-%';
  if n <> 2 then raise exception 'expected the 2 September spirit nights to remain, found %', n; end if;
  select count(*) into n from venues
   where name in ('Pok-e-Jo''s Smokehouse (Parmer)', 'Raising Cane''s Chicken Fingers (N I-35)');
  if n <> 0 then raise exception '% 210 venue rows remain', n; end if;
end $$;

commit;

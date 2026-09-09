-- 192_rollback.sql
--
-- Removes both spirit night events and the two restaurant venue rows.
-- ⚠️ The venues are deleted only if nothing else points at them. Tony C's is a
-- separate row at the same street address and is not affected.

begin;

delete from events
 where slug in ('spirit-night-the-league-2026-09-14',
                'spirit-night-mighty-fine-2026-09-30');

delete from venues v
 where v.name in ('The League Kitchen & Tavern', 'Mighty Fine Burgers (Arbor Walk)')
   and not exists (select 1 from events e where e.venue_id = v.id)
   and not exists (select 1 from games g where g.venue_id = v.id);

commit;

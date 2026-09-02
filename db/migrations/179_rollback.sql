-- 179_rollback.sql — returns Whataburger to Gold and recomputes the sequence.

begin;

update sponsors
   set tier_id = (select id from sponsorship_tiers where year = '2026-27' and name = 'Gold'),
       updated_at = now()
 where year = '2026-27' and name = 'Whataburger';

with ranked as (
  select s.id, row_number() over (order by t.price_cents desc, s.name) as rn
    from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor'
)
update sponsors s set sort_order = ranked.rn, updated_at = now()
  from ranked where s.id = ranked.id and s.sort_order is distinct from ranked.rn;

commit;

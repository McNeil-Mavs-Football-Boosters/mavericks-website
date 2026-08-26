-- 164_rollback.sql — removes the three 2026-08-26 Gold sponsors and recomputes
-- the sequence.
--
-- Leaves the three logo files in the sponsor-logos bucket. Storage is not
-- transactional with the database, and orphan PNGs cost nothing while deleted
-- ones would have to be re-sourced and re-prepared. `prep_gold_2026_08.py` can
-- rebuild them from the pinned sources if it ever comes to that.
--
-- Does NOT touch `sponsorship_tiers.available`. Migration 164 deliberately left
-- Gold closed for sale, so there is nothing to undo there.

begin;

delete from sponsors
 where year = '2026-27'
   and name in ('Raising Cane''s Chicken Fingers',
                'Pok-E-Jo''s Smokehouse',
                'Whataburger');

with ranked as (
  select s.id, row_number() over (order by t.price_cents desc, s.name) as rn
  from sponsors s
  join sponsorship_tiers t on t.id = s.tier_id
  where s.year = '2026-27' and s.kind = 'sponsor'
)
update sponsors s
set sort_order = ranked.rn
from ranked
where s.id = ranked.id
  and s.sort_order is distinct from ranked.rn;

do $$
declare n int;
begin
  select count(*) into n from sponsors
   where year='2026-27'
     and name in ('Raising Cane''s Chicken Fingers',
                  'Pok-E-Jo''s Smokehouse',
                  'Whataburger');
  if n <> 0 then raise exception '% of the three rows survived rollback', n; end if;

  select count(*) into n from sponsors where year='2026-27' and kind='sponsor';
  if n <> 14 then raise exception 'expected 14 paid sponsors after rollback, found %', n; end if;
  if (select max(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> n
     or (select min(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> 1 then
    raise exception 'sort_order not contiguous after rollback';
  end if;
end $$;

commit;

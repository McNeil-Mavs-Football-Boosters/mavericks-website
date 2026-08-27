-- 167_rollback.sql — removes Airborne Balloons & Events, recomputes the sequence.
--
-- Leaves the logo in the sponsor-logos bucket, same reasoning as 164_rollback:
-- storage is not transactional with the database, and an orphan PNG costs
-- nothing while a deleted one has to be re-sourced. The pinned .ai and
-- prep_airborne_2026_08.py can rebuild it regardless.
--
-- Does NOT touch sponsorship_tiers.available; 167 left Platinum closed.

begin;

delete from sponsors where year = '2026-27' and name = 'Airborne Balloons & Events';

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
   where year='2026-27' and name='Airborne Balloons & Events';
  if n <> 0 then raise exception 'Airborne survived rollback'; end if;

  select count(*) into n from sponsors where year='2026-27' and kind='sponsor';
  if n <> 17 then raise exception 'expected 17 paid sponsors after rollback, found %', n; end if;
  if (select max(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> n
     or (select min(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> 1 then
    raise exception 'sort_order not contiguous after rollback';
  end if;
end $$;

commit;

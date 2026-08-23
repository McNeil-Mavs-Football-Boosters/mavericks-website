-- 154_rollback.sql — removes Batrice Law Firm and recomputes the sequence.
--
-- Leaves the logo file in the sponsor-logos bucket. Storage is not
-- transactional with the database, and an orphan PNG costs nothing while a
-- deleted one would have to be re-sourced from the firm.

begin;

delete from sponsors where year = '2026-27' and name = 'Batrice Law Firm';

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
  select count(*) into n from sponsors where year='2026-27' and name='Batrice Law Firm';
  if n <> 0 then raise exception 'Batrice row survived rollback'; end if;

  select count(*) into n from sponsors where year='2026-27' and kind='sponsor';
  if (select max(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> n then
    raise exception 'sort_order not contiguous after rollback';
  end if;
end $$;

commit;

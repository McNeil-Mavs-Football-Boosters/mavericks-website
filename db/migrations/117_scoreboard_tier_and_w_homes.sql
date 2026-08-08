-- 117_scoreboard_tier_and_w_homes.sql
--
-- Three things, all from Jeremy 2026-08-08:
--   1. W Homes Collective joins as a GOLD sponsor.
--   2. Rudy's BBQ is a PAYING SPONSOR after all — $3,000 for two years as the
--      Scoreboard sponsor — so it moves back out of Community Partners.
--   3. The Scoreboard tier gets an explicit showcase rank so it displays just
--      above Platinum rather than above Diamond.
--
-- ── RUDY'S, ONE MORE TIME ──
-- This is the FIFTH state change for this one row, so the history matters:
--   041 seeded as an MVP placeholder · 060 removed as fake · 094 re-added on a
--   bad confirmation · 106 carried into 2026-27 · 111 deactivated ("not a
--   sponsor and never was") · 115 reactivated as a Community Partner (meals) ·
--   117 (this) converts to a PAYING Scoreboard sponsor.
-- Jeremy confirmed they paid $3,000 for a two-season scoreboard sponsorship, and
-- his own headcount ("on the homepage you'll be up to 8" = 6 existing + W Homes
-- + Rudy's) independently confirms Rudy's belongs on the sponsor side now.
--
-- ⚠️ Rudy's is removed from Community Partners rather than listed in both.
-- Paying sponsor supersedes in-kind acknowledgment; showing one business in both
-- places reads as double-counting. They may well still be donating meals — if
-- both should show, that's a deliberate call to make, not a default.
-- Partners drop 8 -> 7.
--
-- STILL a conversion, never an INSERT — same reason as 115. The row keeps its id
-- and created_at through all of this.
--
-- ── WHY showcase_rank_cents EXISTS ──
-- /sponsors orders tiers by price_cents DESC. Scoreboard's price_cents is
-- 300000 ($3,000 total), which would sort it ABOVE Diamond ($2,500/season) —
-- but it is a TWO-SEASON commitment, so its annualised value is $1,500, level
-- with Platinum. Jeremy's call: display it just above Platinum.
--
-- Rather than fake the price (it really is $3,000, and /boosters/sponsor sells
-- it at that number), this adds an explicit, nullable showcase rank. NULL means
-- "rank by price", so every existing tier is unaffected and nothing had to be
-- backfilled. Only a tier whose term differs from one season needs a value.
-- 175000 sits between Platinum (150000) and Diamond (250000).

begin;

alter table sponsorship_tiers
  add column if not exists showcase_rank_cents integer;

comment on column sponsorship_tiers.showcase_rank_cents is
  'Optional override for /sponsors showcase ordering, in cents. NULL = rank by '
  'price_cents. Exists for multi-season tiers whose headline price does not '
  'reflect their per-season value (Scoreboard is $3,000 across two seasons, so '
  'it ranks near Platinum''s $1,500/season rather than above Diamond).';

update sponsorship_tiers
set showcase_rank_cents = 175000
where year = '2026-27' and name = 'Scoreboard';

-- Guards: fail loudly rather than silently updating nothing.
do $$
declare
  n_rudys int;
  n_score int;
  n_gold  int;
begin
  select count(*) into n_rudys from sponsors
    where year = '2026-27' and name = 'Rudy''s BBQ';
  select count(*) into n_score from sponsorship_tiers
    where year = '2026-27' and name = 'Scoreboard' and active;
  select count(*) into n_gold from sponsorship_tiers
    where year = '2026-27' and name = 'Gold' and active;

  if n_rudys <> 1 then
    raise exception 'Expected 1 Rudy''s row for 2026-27, found %', n_rudys;
  end if;
  if n_score <> 1 then
    raise exception 'Expected 1 active Scoreboard tier, found %', n_score;
  end if;
  if n_gold <> 1 then
    raise exception 'Expected 1 active Gold tier, found %', n_gold;
  end if;
end $$;

-- Rudy's: community partner -> paying Scoreboard sponsor, first in display order.
update sponsors
set kind       = 'sponsor',
    tier_id    = (select id from sponsorship_tiers
                  where year = '2026-27' and name = 'Scoreboard' and active),
    sort_order = 1,
    active     = true
where year = '2026-27'
  and name = 'Rudy''s BBQ';

-- Renumber so the homepage carousel order is explicit and gap-free, with the
-- largest commitment first. The carousel pins whichever sponsor sorts first.
update sponsors set sort_order = 2 where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order = 3 where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order = 4 where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order = 6 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order = 7 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order = 8 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

-- W Homes Collective, Gold. sort_order 5 puts it immediately after Laurie Flood,
-- the other Gold sponsor.
insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'W Homes Collective', 'w-homes-collective.png', 'https://whomescollective.com/',
       (select id from sponsorship_tiers where year='2026-27' and name='Gold' and active),
       '2026-27', 'sponsor', true, 5, false
where not exists (
  select 1 from sponsors where name = 'W Homes Collective' and year = '2026-27'
);

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   left join sponsorship_tiers t on t.id = s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> 8 rows, Rudy's/Scoreboard first, W Homes/Gold fifth
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 8, community_partner 7

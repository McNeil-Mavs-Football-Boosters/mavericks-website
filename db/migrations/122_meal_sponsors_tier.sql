-- 122_meal_sponsors_tier.sql
--
-- New "Meal" level, displayed between Platinum and Gold, holding the businesses
-- that feed the teams. Jeremy 2026-08-09.
--
-- Members: Mighty Fine Burgers, The League Kitchen & Tavern, Tony C's Coal Fired
-- Pizza. All three move OUT of Community Partners and onto the sponsor side.
--
-- ⚠️ RUDY'S STAYS ON SCOREBOARD. Jeremy listed Rudy's among the meal sponsors
-- but said explicitly "leave rudy's as scoreboard", so its tier is untouched —
-- Scoreboard outranks Meal and is what they actually paid for. What DOES change
-- is that Rudy's leaves Community Partners with the other three, so
-- provides_in_kind goes back to false. Rudy's therefore appears exactly once,
-- under Scoreboard. (That flag was added by 119 for the opposite reason two days
-- ago; it stays on the table because it is still the right mechanism, just no
-- longer true of anyone right now.)
--
-- ── Tier NAME is "Meal", not "Meal Sponsors" ──
-- /sponsors renders its heading as `{tier.name} Sponsors`, so "Meal Sponsors"
-- would print "MEAL SPONSORS SPONSORS". Same convention as Scoreboard/Blue/Gold.
--
-- ── Why price_cents = 0 and a showcase rank ──
-- A meal sponsor gives food, not money, so there is no honest dollar price.
-- price_cents 0 would sort it dead last on /sponsors, hence
-- showcase_rank_cents = 125000, between Gold (100000) and Platinum (150000) —
-- exactly the slot asked for. Same mechanism migration 117 added for Scoreboard.
--
-- ── New `sellable` column: why this tier must NOT reach /boosters/sponsor ──
-- That page builds the purchasable ladder from every active tier. Without a
-- guard, Meal would render as a buyable level showing "In-kind" and NO benefits,
-- inviting people to sign up for something with no defined price or perks.
-- `active` cannot express this: /sponsors filters on active too, so switching it
-- off would hide the tier from the showcase as well — the one place it must
-- appear. Hence a separate flag.
-- ⚠️ OPEN QUESTION for Jeremy: if meal sponsorship should actually be sellable,
-- flip sellable to true and give the tier a price/term and perks copy. Left
-- unsellable because inventing benefits text for a level nobody has defined
-- would be fabrication.

begin;

alter table sponsorship_tiers
  add column if not exists sellable boolean not null default true;

comment on column sponsorship_tiers.sellable is
  'FALSE = display-only: the tier groups sponsors on /sponsors but is NOT offered '
  'on the /boosters/sponsor sign-up ladder. For recognition groupings with no '
  'price or published benefits (Meal). Distinct from `active`, which hides a tier '
  'from BOTH surfaces.';

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers
    where year='2026-27' and name in ('Gold','Platinum') and active;
  if n <> 2 then
    raise exception 'Expected active Gold and Platinum tiers, found %', n;
  end if;
  select count(*) into n from sponsors
    where year='2026-27' and active
      and name in ('Mighty Fine Burgers','The League Kitchen & Tavern','Tony C''s Coal Fired Pizza');
  if n <> 3 then
    raise exception 'Expected the 3 meal businesses, found %', n;
  end if;
end $$;

insert into sponsorship_tiers
  (name, price_cents, description, perks, sort_order, active, year,
   is_addon, price_flexible, price_display, showcase_rank_cents, sellable)
select 'Meal', 0,
       'Local restaurants feeding the McNeil Football teams.',
       '[]'::jsonb, 3, true, '2026-27', false, true, 'In-kind', 125000, false
where not exists (
  select 1 from sponsorship_tiers where year='2026-27' and name='Meal'
);

update sponsors
set kind             = 'sponsor',
    provides_in_kind = false,
    tier_id          = (select id from sponsorship_tiers
                        where year='2026-27' and name='Meal'),
    sort_order       = v.ord
from (values
  ('Mighty Fine Burgers', 4),
  ('The League Kitchen & Tavern', 5),
  ('Tony C''s Coal Fired Pizza', 6)
) as v(nm, ord)
where sponsors.year='2026-27' and sponsors.name = v.nm;

-- Rudy's: out of Community Partners, tier untouched.
update sponsors set provides_in_kind = false
where year='2026-27' and name='Rudy''s BBQ';

-- Renumber the rest so carousel order still tracks tier order.
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   left join sponsorship_tiers t on t.id=s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> 11 rows; Scoreboard, Platinum x2, Meal x3, Gold x2, Blue x3
--   select name from sponsors where year='2026-27' and active
--     and (kind='community_partner' or provides_in_kind) order by name;
--     -> 5: Amy's, Chicoine, Jack Allen's, Phil's, Santiago's

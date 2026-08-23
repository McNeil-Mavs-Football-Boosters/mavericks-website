-- 154_batrice_law_firm_gold.sql
--
-- New Gold sponsor: Batrice Law Firm, $1,000. Jeremy 2026-08-22.
-- Gold is price_cents = 100000, so $1,000 is the correct tier, verified against
-- sponsorship_tiers rather than assumed.
--
-- ⚠️ THE LOGO IS AN INTERIM ASSET AND DOES NOT MEET THE CLUB'S OWN STANDARD.
-- `sponsor_asset_requirements_2026.md` (Kendra, canonical) says: vector
-- preferred, else "the largest available PNG with a transparent background",
-- and explicitly "Do not send screenshots or images copied from a website."
-- What we have is a 260x254 screenshot of their site, resized to the 240px
-- height the other marks use. It renders fine on the web strip and that is all
-- it is good for. **Gold includes a field sign at every varsity game and a
-- business sign on McNeil Drive** - a 246px screenshot cannot produce either,
-- so a vector or large transparent PNG still has to be requested. Publishing
-- the interim file rather than leaving the row logo-less is deliberate: they
-- have paid, and `LogoImg` returns null on a null logo_url, so a missing file
-- means a paid Gold sponsor renders as nothing on /sponsors.
--
-- The navy background is KEPT, not knocked out. The wordmark is white, so a
-- transparent version of this particular file would be invisible on the site's
-- white sponsor cards. Do not "fix" it by removing the background; fix it by
-- getting the real artwork.
--
-- ── SORT_ORDER IS RENUMBERED, NOT APPENDED ──
-- `sort_order` on this table is a single global sequence that encodes
-- tier-then-alphabetical: Platinum 1-2, Gold 3-8, Blue 9-13. /sponsors and
-- /boosters/sponsor both `.order("sort_order")`, so appending Batrice at 14
-- would have printed it last in Gold - after W Homes - breaking the alphabetical
-- run. Rather than hand-shifting eleven rows, the sequence is RECOMPUTED from
-- the data: tier price_cents DESC, then name. Idempotent, and it repairs any
-- drift that already existed.
--
-- Community partners (kind = 'community_partner') are excluded and stay at 0.
-- They are unranked by design and `getCommunityPartners` orders them by name.
--
-- DB-ONLY, NO DEPLOY. /sponsors, /boosters/sponsor and the homepage strip all
-- read at request time.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, provides_in_kind, sort_order)
select 'Batrice Law Firm',
       'batrice-law-firm.png',
       'https://batricelawfirm.com/',
       t.id,
       '2026-27',
       'sponsor',
       true,
       false,
       0                      -- placeholder; the renumber below assigns the real value
from sponsorship_tiers t
where t.year = '2026-27' and t.name = 'Gold'
  and not exists (
    select 1 from sponsors s where s.year = '2026-27' and s.name = 'Batrice Law Firm'
  );

-- Recompute the whole paid-sponsor sequence: tier value desc, then name.
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
declare n int; so int;
begin
  -- The row exists exactly once, in Gold, with the right link and logo.
  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.name = 'Batrice Law Firm'
     and t.name = 'Gold' and t.price_cents = 100000
     and s.website_url = 'https://batricelawfirm.com/'
     and s.logo_url = 'batrice-law-firm.png'
     and s.kind = 'sponsor' and s.active and not s.provides_in_kind;
  if n <> 1 then
    raise exception 'Batrice Law Firm not inserted as expected (matched % rows)', n;
  end if;

  -- Gold goes from 6 to 7.
  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor' and t.name = 'Gold';
  if n <> 7 then
    raise exception 'expected 7 Gold sponsors, found %', n;
  end if;

  -- Alphabetically first in Gold, so it must sit immediately after Platinum's two.
  select s.sort_order into so from sponsors s
   where s.year = '2026-27' and s.name = 'Batrice Law Firm';
  if so <> 3 then
    raise exception 'Batrice landed at sort_order %, expected 3 (first in Gold)', so;
  end if;

  -- The sequence must be 1..N with no gaps and no duplicates.
  select count(*) into n from sponsors
   where year = '2026-27' and kind = 'sponsor';
  if (select count(distinct sort_order) from sponsors where year='2026-27' and kind='sponsor') <> n then
    raise exception 'duplicate sort_order values among the % paid sponsors', n;
  end if;
  if (select max(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> n
     or (select min(sort_order) from sponsors where year='2026-27' and kind='sponsor') <> 1 then
    raise exception 'sort_order is not a contiguous 1..% sequence', n;
  end if;

  -- Partners untouched.
  select count(*) into n from sponsors
   where year = '2026-27' and kind = 'community_partner' and sort_order <> 0;
  if n <> 0 then
    raise exception '% community partners had their sort_order disturbed', n;
  end if;
end $$;

commit;

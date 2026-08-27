-- 167_airborne_balloons_platinum.sql
--
-- New Platinum sponsor: Airborne Balloons & Events, $1,500. Jeremy 2026-08-26.
-- Platinum is price_cents = 150000, verified against sponsorship_tiers rather
-- than assumed. Platinum 2 -> 3; paid sponsors 17 -> 18. Community partners
-- unchanged at 6.
--
-- ⚠️ AIRBORNE LANDS AT sort_order 1 — AHEAD OF BOTH EXISTING PLATINUM ROWS.
-- "Airborne" sorts before "Capstone", so this is the first sponsor addition
-- that displaces the top of the whole sequence rather than slotting into the
-- middle. Every paid row shifts by one. That is exactly why 154 recomputes the
-- sequence from the data instead of hand-shifting, and why appending at max+1
-- has never been acceptable here.
--
-- Platinum, like Gold, is `available = false` (closed for sale, migration 160).
-- Same non-contradiction as 164: the roster surfaces filter tier `active`, not
-- `available`, so a sponsor who committed at Platinum publishes normally while
-- the level stays closed to new buyers. **Do NOT reopen Platinum as part of
-- this** — asserted at the end.
--
-- ── THE WEBSITE IS A PLACEHOLDER, AND IT IS STILL THE RIGHT LINK ──
-- airborneatx.com returns 200 with the title "Coming Soon" and the body "new
-- website coming soon! inquire now - please fill out the form below". It is
-- their real domain (their contact is ashley@airborneatx.com) and it is a
-- branded page with a working inquiry form, so a click lands somewhere useful.
--
-- ⚠️ This is NOT the Capstone case that 106 left NULL. That URL was a guess at
-- the domain and served an EMPTY 114-byte page; this one was supplied by Jeremy,
-- matches the sponsor's own email domain, and has content. Swap it when their
-- real site launches — one UPDATE, no migration needed for a URL change.
--
-- ── LOGO ──
-- Vector: an Illustrator .ai saved with the PDF-compatible stream, so it opened
-- directly. 1200x280, transparent, prepared by
-- `MavericksWebsite/partner_logos/prep_airborne_2026_08.py` from a pinned source.
--
-- ⚠️ "Balloons & Events" IS BLACK SCRIPT AND NEEDS A LIGHT BACKGROUND. Verified
-- before shipping that all three sponsor surfaces are light: /sponsors cards,
-- /boosters/sponsor cards (bg-white), and the homepage carousel, which sits in a
-- plain container section with no background class and inherits the page white.
-- **If a sponsor block is ever moved onto bg-mavs-navy this logo loses its
-- entire second line** — the inverse of the white Whataburger file 164 rejected.
--
-- ⚠️ It is 4.3:1, the widest mark in the bucket. Platinum's box is
-- `max-h-40 max-w-[min(320px,100%)]`, so width binds first and it renders about
-- 320x75 — shorter than the two square-ish Platinum logos beside it. That is the
-- bounding box working, not a sizing bug.
--
-- DB-ONLY, NO DEPLOY.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, provides_in_kind, sort_order)
select 'Airborne Balloons & Events',
       'airborne-balloons.png',
       'https://airborneatx.com/',
       t.id, '2026-27', 'sponsor', true, false,
       0                      -- placeholder; the renumber below assigns the real value
from sponsorship_tiers t
where t.year = '2026-27' and t.name = 'Platinum'
  and not exists (
    select 1 from sponsors s
     where s.year = '2026-27' and s.name = 'Airborne Balloons & Events'
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
  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.name = 'Airborne Balloons & Events'
     and t.name = 'Platinum' and t.price_cents = 150000
     and s.website_url = 'https://airborneatx.com/'
     and s.logo_url = 'airborne-balloons.png'
     and s.kind = 'sponsor' and s.active and not s.provides_in_kind;
  if n <> 1 then
    raise exception 'Airborne not inserted as expected (matched % rows)', n;
  end if;

  -- First alphabetically in the top tier, so it takes the top of the sequence.
  select s.sort_order into so from sponsors s
   where s.year = '2026-27' and s.name = 'Airborne Balloons & Events';
  if so <> 1 then
    raise exception 'Airborne landed at sort_order %, expected 1', so;
  end if;

  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor' and t.name = 'Platinum';
  if n <> 3 then raise exception 'expected 3 Platinum sponsors, found %', n; end if;

  select count(*) into n from sponsors
   where year = '2026-27' and kind = 'sponsor' and active;
  if n <> 18 then raise exception 'expected 18 active paid sponsors, found %', n; end if;

  -- Contiguous 1..N, no gaps, no duplicates.
  select count(*) into n from sponsors where year = '2026-27' and kind = 'sponsor';
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
  if n <> 0 then raise exception '% community partners disturbed', n; end if;

  -- Platinum must still be CLOSED for sale.
  select count(*) into n from sponsorship_tiers
   where year = '2026-27' and name = 'Platinum' and available;
  if n <> 0 then
    raise exception 'Platinum was reopened for sale; this migration must not do that';
  end if;
end $$;

commit;

-- 164_three_gold_sponsors.sql
--
-- Three new Gold sponsors, $1,000 each. Jeremy 2026-08-26:
--   Raising Cane's Chicken Fingers  (I-35 @ Parmer, Austin)
--   Pok-E-Jo's Smokehouse           (Parmer Lane)
--   Whataburger
--
-- Gold is price_cents = 100000, verified against sponsorship_tiers rather than
-- assumed, same as 154. Gold goes 7 -> 10; paid sponsors 14 -> 17. Community
-- partners stay at 6 and are untouched.
--
-- ── GOLD IS CURRENTLY `available = false` AND THAT IS NOT A CONTRADICTION ──
-- Kendra closed Gold on 2026-08-25 (migration 160); Blue was reopened the same
-- day (163). `available` gates only whether /boosters/sponsor will SELL the
-- level — the card renders greyed out with a dead CTA. It has nothing to do
-- with the roster: /sponsors, /boosters/sponsor and the homepage strip all
-- read `sponsors` joined to `sponsorship_tiers` filtered on tier `active`, not
-- `available` (app/sponsors/page.tsx). So these three publish normally while
-- Gold stays closed to new buyers, which is exactly right for sponsors who
-- committed at that level. **Do NOT flip Gold's `available` as part of adding
-- them** — that would reopen the level for sale, which nobody asked for.
--
-- ── SORT_ORDER IS RENUMBERED, NOT APPENDED (copied verbatim from 154) ──
-- `sort_order` is a single global sequence encoding tier-then-alphabetical:
-- Platinum 1-2, Gold 3-9, Blue 10-14 before this migration. Both /sponsors and
-- /boosters/sponsor `.order("sort_order")`, so appending at max+1 would print
-- all three last in Gold and break the alphabetical run. The sequence is
-- RECOMPUTED from the data instead: tier price_cents DESC, then name.
-- Idempotent, and it repairs any drift that already existed.
--
-- Under this database's collation that lands the new rows at Gold 6 (Pok-E-Jo's,
-- between Mighty Fine and Rudy's), Gold 7 (Raising Cane's) and Gold 12
-- (Whataburger, AFTER W Homes Collective — the space in "W Homes" sorts before
-- "Wh", it is not ignored). The assertion block below pins all three, so a
-- collation change surfaces here instead of silently reshuffling the page.
--
-- Community partners (kind = 'community_partner') are excluded and stay at 0.
--
-- ── LOGOS ──
-- All three are VECTOR-sourced, 1200px wide, transparent, prepared by
-- `MavericksWebsite/partner_logos/prep_gold_2026_08.py` from sources pinned in
-- that folder. Uploaded to the `sponsor-logos` bucket; `logo_url` is the bare
-- filename and publicStorageUrl() builds the URL.
--
-- ⚠️ WHATABURGER'S SUPPLIED FILE WAS UNUSABLE AND WAS NOT SHIPPED. What came in
-- was whataburger.com's nav asset: 77x75 and entirely WHITE, the reversed
-- variant meant for use on Whataburger orange. The sponsor cards are white, so
-- shipping it would have rendered a paid Gold sponsor as a blank rectangle.
-- That is NOT the Batrice "publish the best available asset anyway" case
-- (Jeremy 2026-08-22) — that rule exists because a null logo_url renders as
-- NOTHING, and a white logo on a white card renders as nothing too. Shipping it
-- would have honoured the letter of the rule and defeated its whole point. The
-- mark used is Whataburger's own current lockup in vector and in their orange
-- (Wikimedia Commons `Whataburger logo.svg`, public domain), cross-checked
-- against their own site's white wordmark SVG and their orange app icon. If
-- Whataburger sends real artwork, swap the file.
--
-- ⚠️ RAISING CANE'S SENT A STYLE GUIDE ALONG WITH THE LOGO, and two of its rules
-- bind on the PHYSICAL Gold deliverables, not the web card:
--   * "never reduce the logo below one inch wide" — fine at ~266px on the card.
--   * clear space of 1/4x on every side — the stored PNG is cropped tight to
--     the ink on purpose, because the card supplies its own padding.
-- Gold includes a field sign at every varsity game and a business sign on
-- McNeil Drive. Whoever lays those out has to add the clear space back and
-- should use the vector PDF in partner_logos/sources/gold-2026-08/, not this
-- PNG. Their improper-usage list also forbids recolouring, rotating, uneven
-- scaling, recreating the logo, and removing the registration mark.
--
-- DB-ONLY, NO DEPLOY. /sponsors and /boosters/sponsor are force-dynamic; the
-- homepage strip is ISR revalidate=60 and lags about a minute. That lag is not
-- a failed migration.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, provides_in_kind, sort_order)
select v.name, v.logo_url, v.website_url,
       t.id, '2026-27', 'sponsor', true, false,
       0                      -- placeholder; the renumber below assigns the real value
from (values
        ('Raising Cane''s Chicken Fingers', 'raising-canes.png',
         'https://locations.raisingcanes.com/tx/austin/12901-n-interstate-hwy-35'),
        ('Pok-E-Jo''s Smokehouse', 'pok-e-jos-smokehouse.png',
         'https://www.pokejos.com/palmer-lane'),
        ('Whataburger', 'whataburger.png',
         'https://whataburger.com/home')
     ) as v(name, logo_url, website_url)
join sponsorship_tiers t
  on t.year = '2026-27' and t.name = 'Gold'
where not exists (
  select 1 from sponsors s where s.year = '2026-27' and s.name = v.name
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
declare n int; got int; want int; nm text;
begin
  -- Each row exists exactly once, in Gold, with the right link and logo, and
  -- lands at the sort_order the tier-then-alphabetical recompute should give it.
  for nm, want in
    select * from (values
      ('Pok-E-Jo''s Smokehouse', 6),
      ('Raising Cane''s Chicken Fingers', 7),
      ('Whataburger', 12)
    ) as x(name, expected)
  loop
    select count(*) into n from sponsors s
     join sponsorship_tiers t on t.id = s.tier_id
     where s.year = '2026-27' and s.name = nm
       and t.name = 'Gold' and t.price_cents = 100000
       and s.kind = 'sponsor' and s.active and not s.provides_in_kind
       and s.website_url is not null and s.logo_url is not null;
    if n <> 1 then
      raise exception '% not inserted as expected (matched % rows)', nm, n;
    end if;

    select s.sort_order into got from sponsors s
     where s.year = '2026-27' and s.name = nm;
    if got <> want then
      raise exception '% landed at sort_order %, expected % (collation change?)', nm, got, want;
    end if;
  end loop;

  -- Gold goes from 7 to 10.
  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor' and t.name = 'Gold';
  if n <> 10 then
    raise exception 'expected 10 Gold sponsors, found %', n;
  end if;

  -- 17 paid sponsors total.
  select count(*) into n from sponsors
   where year = '2026-27' and kind = 'sponsor' and active;
  if n <> 17 then
    raise exception 'expected 17 active paid sponsors, found %', n;
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

  -- Gold must still be CLOSED for sale. Adding sponsors at a level is not the
  -- same act as reopening it, and conflating the two is a one-word mistake.
  select count(*) into n from sponsorship_tiers
   where year = '2026-27' and name = 'Gold' and available;
  if n <> 0 then
    raise exception 'Gold was reopened for sale; this migration must not do that';
  end if;
end $$;

commit;

-- 106_sponsors_2026_27.sql
--
-- Advances the sponsor surfaces to the 2026-27 season.
--
-- WHY FLIPPING current_year IS SAFE NOW: after the coaches (055), schedule
-- (056), practice (077) and roster (095) decouplings, `current_year` governs
-- ONLY sponsors + sponsorship_tiers. Verified before writing this: the only
-- code destructuring the real `current_year` is app/page.tsx (sponsor strip +
-- MVP tier lookup), app/sponsors/page.tsx and app/boosters/sponsor/page.tsx.
-- The schedule and roster pages destructure their own year and alias it to a
-- local named `current_year`, which is why a naive grep looks alarming.
--
-- The 2025-26 sponsors and tiers are LEFT IN PLACE, not deleted. Flipping the
-- year makes them invisible on every public surface, which is what "remove the
-- old ones" needs, while keeping last season's showcase recoverable. Rolling
-- 106 back restores the 2025-26 lineup exactly.
--
-- Dropped from the public site by this migration (2025-26 only, rows retained):
-- AutoNation Chevrolet West Austin, Sunflower Bank, Dave's Ultimate
-- Automotive, TKO Heating and Air.
--
-- Carried forward: Rudy's BBQ (MVP, per Jeremy "leave Rudy's at top level for
-- now"), Luv Braces (Gold -> Blue) and Laurie Flood (Gold -> Gold), both
-- reusing their existing logo objects.
--
-- New logos uploaded to the sponsor-logos bucket:
--   mama-bettys-tex-mex.png       rasterized from the supplied SVG at 1200px
--                                 wide with a transparent background -- the
--                                 bucket only allows png/jpeg/webp, so the SVG
--                                 could not be uploaded as-is. Rendered through
--                                 headless Chrome so the navy->maroon gradient
--                                 survives.
--   north-austin-oral-surgery.png the colored (teal + navy) mark, converted
--                                 from palette to RGBA. Chosen over the
--                                 all-navy variant as it is brand-accurate.
--   capstone-acquisitions.png     converted from webp. White background kept
--                                 deliberately: the "C" is white-on-red, so
--                                 keying out white would eat part of the mark.
--                                 Invisible against the white page.
--
-- website_url is NULL for Capstone Acquisitions and Mama Betty's -- no verified
-- URL. capstoneacquisitions.com resolves but serves an empty 114-byte page, and
-- no Mama Betty's domain resolved, so neither was linked rather than shipping a
-- wrong link on a paying sponsor. Both components render a bare logo when
-- website_url is null (checked). Add them when the real URLs are known.

begin;

-- 1. Clone the full 9-row tier ladder to 2026-27. INSERT...SELECT rather than
--    re-typing so every column (perks, badge_label, term_label, price_display,
--    is_addon, price_flexible) carries over exactly. Prices are unchanged and
--    match the levels Jeremy quoted: Blue 500, Gold 1000, Platinum 1500,
--    Diamond 2500, MVP 5000.
insert into sponsorship_tiers
  (name, price_cents, description, perks, sort_order, active, year,
   badge_label, is_addon, price_flexible, term_label, price_display)
select
  name, price_cents, description, perks, sort_order, active, '2026-27',
  badge_label, is_addon, price_flexible, term_label, price_display
from sponsorship_tiers
where year = '2025-26'
  and not exists (select 1 from sponsorship_tiers where year = '2026-27');

-- 2. The 2026-27 sponsor lineup. tier_id resolved by name against the rows just
--    created, so no hardcoded uuids.
insert into sponsors (name, logo_url, website_url, tier_id, sort_order, year, active)
select v.name, v.logo_url, v.website_url, t.id, v.sort_order, '2026-27', true
from (values
  ('Rudy''s BBQ',                  'rudys-bbq.png',                 'https://rudysbbq.com',                  'MVP',      1),
  ('Capstone Acquisitions',        'capstone-acquisitions.png',     null,                                    'Platinum', 2),
  ('North Austin Oral Surgery',    'north-austin-oral-surgery.png', 'https://northaustinoralsurgery.com',    'Platinum', 3),
  ('Laurie Flood Real Estate Team','laurie-flood-realtor.png',      'https://austintexasbestrealestate.com', 'Gold',     4),
  ('Luv Braces',                   'luv-braces.png',                'https://luvbraces.com',                 'Blue',     5),
  ('Mama Betty''s Tex-Mex',        'mama-bettys-tex-mex.png',       null,                                    'Blue',     6)
) as v(name, logo_url, website_url, tier_name, sort_order)
join sponsorship_tiers t
  on t.year = '2026-27' and t.name = v.tier_name and t.active
where not exists (
  select 1 from sponsors s where s.year = '2026-27' and s.name = v.name
);

-- 3. Point the sponsor surfaces at the new season.
update site_settings set current_year = '2026-27';

commit;

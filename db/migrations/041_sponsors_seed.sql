-- 041_sponsors_seed.sql
-- Seed 2025-26 sponsors (7 rows: 1 MVP placeholder + 6 last-year Golds),
-- 1 "Become a Sponsor" headline_cta hero tile, and 3 sponsor_spotlight hero
-- tiles for the featured sponsors. Per
-- docs/specs/commit_sponsors_seed_and_carousel_spec_v2.md.
--
-- Note on tier year: migration 030's year split relabeled rosters/practice/
-- coaches/games from 2026-27 to 2025-26 to match site_settings.current_year,
-- but missed sponsorship_tiers. Per content_map_v2.md the /sponsors and
-- homepage sponsor queries read by current_year, so this migration also
-- relabels the sponsorship_tiers rows from 2026-27 to 2025-26 before
-- inserting sponsors (otherwise the tier_id lookups below would be NULL).

begin;

-- Pre-step: relabel sponsorship_tiers year to match current_year (2025-26).
update sponsorship_tiers
  set year = '2025-26'
  where year = '2026-27';

-- Sponsors (uses tier IDs by name).
do $$
declare
  mvp_tier uuid;
  gold_tier uuid;
begin
  select id into mvp_tier from sponsorship_tiers where year = '2025-26' and name = 'MVP';
  select id into gold_tier from sponsorship_tiers where year = '2025-26' and name = 'Gold';

  if mvp_tier is null then
    raise exception 'MVP tier not found for year 2025-26';
  end if;
  if gold_tier is null then
    raise exception 'Gold tier not found for year 2025-26';
  end if;

  insert into sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active) values
    ('Rudy''s BBQ',
     'rudys-bbq.png',
     'https://rudysbbq.com',
     mvp_tier, '2025-26', true, 1, true),
    ('AutoNation Chevrolet West Austin',
     'autonation-chevrolet-west-austin.png',
     'https://www.autonationchevroletwestaustin.com',
     gold_tier, '2025-26', true, 2, true),
    ('Sunflower Bank',
     'sunflower-bank.png',
     'https://www.sunflowerbank.com',
     gold_tier, '2025-26', true, 3, true),
    ('LUV Braces',
     'luv-braces.png',
     'https://luvbraces.com',
     gold_tier, '2025-26', false, 4, true),
    ('Dave''s Ultimate Automotive',
     'daves-ultimate-automotive.png',
     'https://davesultimateautomotive.com',
     gold_tier, '2025-26', false, 5, true),
    ('TKO Heating and Air',
     'tko-heating-and-air.png',
     'https://www.tkomechanical.com',
     gold_tier, '2025-26', false, 6, true),
    ('Laurie Flood, Realtor',
     'laurie-flood-realtor.png',
     'https://austintexasbestrealestate.com',
     gold_tier, '2025-26', false, 7, true);
end $$;

-- New "Become a Sponsor" headline_cta tile (Pool A → 4 tiles).
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('headline_cta',
   '{"headline":"Become a Sponsor","subhead":"Five tiers, real visibility. Reach every Mavs family from August through December.","cta_label":"Sponsorship Info","cta_url":"/boosters/sponsor"}'::jsonb,
   4, true);

-- Sponsor spotlight tiles for the 3 featured sponsors (Pool B).
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('sponsor_spotlight',
   '{"sponsor_name":"Rudy''s BBQ","logo_bucket":"sponsor-logos","logo_storage_path":"rudys-bbq.png","tagline":null,"website_url":"https://rudysbbq.com"}'::jsonb,
   101, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"AutoNation Chevrolet West Austin","logo_bucket":"sponsor-logos","logo_storage_path":"autonation-chevrolet-west-austin.png","tagline":null,"website_url":"https://www.autonationchevroletwestaustin.com"}'::jsonb,
   102, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"Sunflower Bank","logo_bucket":"sponsor-logos","logo_storage_path":"sunflower-bank.png","tagline":null,"website_url":"https://www.sunflowerbank.com"}'::jsonb,
   103, true);

commit;

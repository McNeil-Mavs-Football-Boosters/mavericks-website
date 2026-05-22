-- 043_remove_sponsor_spotlight_tiles.sql
-- Remove the 3 sponsor_spotlight hero tiles seeded by migration 041
-- (Rudy's, AutoNation, Sunflower). Jeremy doesn't want sponsor logos
-- rotating in the carousel — the homepage sponsors strip + /sponsors
-- page already cover that. The HeroCarousel two-pool rotation falls
-- back to single-pool CTA-only when sponsorTiles is empty, so this is
-- a DB-only change.

begin;

delete from hero_foreground_tiles
  where tile_type = 'sponsor_spotlight'
  and payload->>'sponsor_name' in (
    'Rudy''s BBQ',
    'AutoNation Chevrolet West Austin',
    'Sunflower Bank'
  );

commit;

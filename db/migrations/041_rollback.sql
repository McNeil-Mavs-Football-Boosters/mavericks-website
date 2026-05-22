-- 041_rollback.sql
-- Reverses 041_sponsors_seed.sql. Removes seeded sponsors, the 3 sponsor
-- spotlight tiles, and the "Become a Sponsor" headline_cta tile. Also
-- re-labels sponsorship_tiers back to 2026-27 to restore pre-041 state.
--
-- This file must NOT be bundled into db/apply_all.sql — the regen pattern
-- in docs/CLAUDE.md skips *_rollback.sql files.

begin;

delete from hero_foreground_tiles
  where tile_type = 'sponsor_spotlight'
  and payload->>'sponsor_name' in (
    'Rudy''s BBQ', 'AutoNation Chevrolet West Austin', 'Sunflower Bank'
  );

delete from hero_foreground_tiles
  where tile_type = 'headline_cta'
  and payload->>'headline' = 'Become a Sponsor';

delete from sponsors where year = '2025-26';

update sponsorship_tiers
  set year = '2026-27'
  where year = '2025-26';

commit;

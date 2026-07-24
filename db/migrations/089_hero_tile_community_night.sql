-- 089_hero_tile_community_night.sql
--
-- Adds a homepage carousel tile (headline_cta) for the Phil's & Amy's Community
-- Night; its CTA links to the event info page. Same payload shape as the other
-- headline_cta tiles (headline / subhead / cta_label / cta_url; cta_url renders
-- via next/link, so an internal path works). sort_order 5 (after the 4 existing).
--
-- Time-limited: deactivate (active=false) after Aug 4 so it doesn't linger.
-- Idempotent: INSERT-if-absent on the cta_url.

BEGIN;

INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order, active)
SELECT 'headline_cta',
  '{"headline":"Phil’s & Amy’s Community Night","subhead":"Tue Aug 4, 4–8 PM at Phil’s Ice House (183). Mention McNeil Football at the register.","cta_label":"Event Details","cta_url":"/events/community-night-phils-amys-2026"}'::jsonb,
  5, true
WHERE NOT EXISTS (
  SELECT 1 FROM hero_foreground_tiles
  WHERE tile_type = 'headline_cta'
    AND payload->>'cta_url' = '/events/community-night-phils-amys-2026'
);

COMMIT;

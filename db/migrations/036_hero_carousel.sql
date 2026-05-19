-- Migration 036: Homepage hero carousel — background images + foreground tiles.
-- Spec: docs/specs/commit_homepage_hero_carousel_spec.md (2026-05-19).
-- Spec calls this 035; renumbered to 036 because 035_fix_rrisd_athletic_forms_url.sql shipped first.
-- Seeds three headline_cta foreground tiles. Background images come in a follow-up migration
-- once Jeremy provides the photo count and alt text.

-- -----------------------------------------------------------------------------
-- hero_background_images: photos that rotate behind everything in the homepage hero
-- -----------------------------------------------------------------------------
CREATE TABLE hero_background_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_path text NOT NULL,         -- e.g. 'hero/hero-01.jpg' inside the site-images bucket
  alt_text text NOT NULL,             -- accessibility; describe the photo
  sort_order int NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX hero_background_images_active_sort_idx
  ON hero_background_images (active, sort_order);

-- -----------------------------------------------------------------------------
-- hero_foreground_tiles: rotating content tiles overlaying the photos.
-- tile_type drives rendering; payload is jsonb for flexibility (see spec for shapes).
-- -----------------------------------------------------------------------------
CREATE TYPE hero_tile_type AS ENUM ('headline_cta', 'sponsor_spotlight');

CREATE TABLE hero_foreground_tiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tile_type hero_tile_type NOT NULL,
  payload jsonb NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX hero_foreground_tiles_active_sort_idx
  ON hero_foreground_tiles (active, sort_order);

-- -----------------------------------------------------------------------------
-- updated_at triggers (reuses touch_updated_at() from migration 006)
-- -----------------------------------------------------------------------------
CREATE TRIGGER touch_hero_background_images BEFORE UPDATE ON hero_background_images
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER touch_hero_foreground_tiles BEFORE UPDATE ON hero_foreground_tiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- -----------------------------------------------------------------------------
-- RLS: public read of active rows. Admin write policies arrive with admin CRUD.
-- -----------------------------------------------------------------------------
ALTER TABLE hero_background_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE hero_foreground_tiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads active hero backgrounds" ON hero_background_images
  FOR SELECT TO anon, authenticated
  USING (active = true);

CREATE POLICY "Anyone reads active hero tiles" ON hero_foreground_tiles
  FOR SELECT TO anon, authenticated
  USING (active = true);

-- -----------------------------------------------------------------------------
-- Seed: three headline_cta foreground tiles per spec.
-- Background images deliberately NOT seeded here.
-- sponsor_spotlight tiles wait for SE Tier 1 sponsor capture (followups.md).
-- -----------------------------------------------------------------------------
INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order) VALUES
  ('headline_cta',
   jsonb_build_object(
     'headline',  'McNeil Mavericks Football',
     'subhead',   'Home of the McNeil Mavericks, Austin, TX',
     'cta_label', 'Join the Booster Club',
     'cta_url',   '/boosters/join'
   ),
   1),
  ('headline_cta',
   jsonb_build_object(
     'headline',  'Support the Mavs',
     'subhead',   'Your booster dues fund equipment, meals, and senior gifts.',
     'cta_label', 'Make a Donation',
     'cta_url',   '/boosters/donate'
   ),
   2),
  ('headline_cta',
   jsonb_build_object(
     'headline',  'Get Involved',
     'subhead',   'Game-day help, banquet planning, sponsor outreach. We need you.',
     'cta_label', 'Volunteer',
     'cta_url',   '/boosters/volunteer'
   ),
   3);

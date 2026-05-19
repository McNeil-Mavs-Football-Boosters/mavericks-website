-- Migration 037: Seed six hero_background_images rows for the homepage carousel.
-- Follow-up to migration 036 (which created the table empty).
-- Source photos: docs/Backgrounds/resized/hero-0{1..6}.jpg, uploaded to the
-- site-images bucket under hero/.

INSERT INTO hero_background_images (storage_path, alt_text, sort_order, active)
VALUES
  ('hero/hero-01.jpg', 'McNeil High School marching band performing at a football game', 1, true),
  ('hero/hero-02.jpg', 'McNeil Mavericks mascot at a football game',                       2, true),
  ('hero/hero-03.jpg', 'McNeil cheer team performing during a football game',              3, true),
  ('hero/hero-04.jpg', 'McNeil cheerleaders on the sideline during a football game',       4, true),
  ('hero/hero-05.jpg', 'McNeil Mavericks player catching a touchdown pass',                5, true),
  ('hero/hero-06.jpg', 'McNeil Mavericks football team running onto the field',            6, true);

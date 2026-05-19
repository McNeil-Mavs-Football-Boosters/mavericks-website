-- Rollback for migration 037: remove the six seeded hero_background_images rows.
-- Targeted by storage_path so it only undoes 037 and leaves any admin-added rows alone.

DELETE FROM hero_background_images
WHERE storage_path IN (
  'hero/hero-01.jpg',
  'hero/hero-02.jpg',
  'hero/hero-03.jpg',
  'hero/hero-04.jpg',
  'hero/hero-05.jpg',
  'hero/hero-06.jpg'
);

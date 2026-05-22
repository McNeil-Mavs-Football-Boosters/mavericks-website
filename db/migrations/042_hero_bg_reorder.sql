-- 042_hero_bg_reorder.sql
-- Swap sort_order between hero-01.jpg (band) and hero-06.jpg (football team
-- running onto the field) so the carousel opens with the team-running image
-- instead of the band. Band moves to the last slot in the rotation; cycle
-- length unchanged.

begin;

update hero_background_images set sort_order = 99 where storage_path = 'hero/hero-06.jpg';
update hero_background_images set sort_order = 6  where storage_path = 'hero/hero-01.jpg';
update hero_background_images set sort_order = 1  where storage_path = 'hero/hero-06.jpg';

commit;

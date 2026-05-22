-- 042_rollback.sql
-- Reverses 042_hero_bg_reorder.sql: restores band (hero-01.jpg) to slot 1
-- and football team running (hero-06.jpg) to slot 6.

begin;

update hero_background_images set sort_order = 99 where storage_path = 'hero/hero-01.jpg';
update hero_background_images set sort_order = 6  where storage_path = 'hero/hero-06.jpg';
update hero_background_images set sort_order = 1  where storage_path = 'hero/hero-01.jpg';

commit;

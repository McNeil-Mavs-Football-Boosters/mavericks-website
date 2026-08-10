-- 124_rollback.sql — restores the Meal tier and its four members.
begin;
update sponsorship_tiers set active = true where year='2026-27' and name='Meal';
update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Meal')
where year='2026-27' and name in
  ('Mighty Fine Burgers','Rudy''s BBQ','The League Kitchen & Tavern','Tony C''s Coal Fired Pizza');
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Rudy''s BBQ';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
commit;

-- 122_rollback.sql — returns the three meal businesses to Community Partners,
-- restores Rudy's in-kind flag, deletes the Meal tier and the sellable column.
-- ⚠️ Dropping `sellable` makes any display-only tier reappear on the
-- /boosters/sponsor sign-up ladder.
begin;

update sponsors set kind='community_partner', tier_id=null, provides_in_kind=false, sort_order=0
where year='2026-27' and name in
  ('Mighty Fine Burgers','The League Kitchen & Tavern','Tony C''s Coal Fired Pizza');

update sponsors set provides_in_kind=true where year='2026-27' and name='Rudy''s BBQ';

update sponsors set sort_order=4 where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=5 where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=6 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=7 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=8 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

delete from sponsorship_tiers where year='2026-27' and name='Meal';
alter table sponsorship_tiers drop column if exists sellable;
commit;

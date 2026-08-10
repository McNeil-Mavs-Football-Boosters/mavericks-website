-- 123_rudys_to_meal.sql
--
-- Rudy's moves from Scoreboard to Meal, and the Scoreboard section comes off
-- /sponsors for now. Jeremy 2026-08-09.
--
-- ⚠️ THE SCOREBOARD TIER IS NOT DEACTIVATED, DELIBERATELY.
-- /sponsors already renders nothing for a tier with no sponsors, so moving
-- Rudy's out is by itself enough to hide the section — no flag needed. Setting
-- the tier inactive would ALSO pull Scoreboard off the /boosters/sponsor sign-up
-- ladder, where it is still a real, sellable $3,000 / two-season add-on that
-- nobody asked to withdraw. Hiding a showcase section and withdrawing a product
-- are different things; this does only the first.
--
-- Rudy's did pay $3,000 for scoreboard placement, so the site no longer shows
-- what they bought. Jeremy said "for now", so treat this as temporary: to undo,
-- move the tier_id back (123_rollback.sql) and the section returns on its own.
--
-- Sponsors renumbered so display order still tracks tier order, with Meal
-- members alphabetical among themselves.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Meal' and active;
  if n <> 1 then raise exception 'Expected 1 active Meal tier, found %', n; end if;
end $$;

update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Meal')
where year='2026-27' and name='Rudy''s BBQ';

update sponsors set sort_order=1  where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=2  where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Rudy''s BBQ';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   join sponsorship_tiers t on t.id=s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> Platinum x2, Meal x4 (incl. Rudy's), Gold x2, Blue x3; no Scoreboard

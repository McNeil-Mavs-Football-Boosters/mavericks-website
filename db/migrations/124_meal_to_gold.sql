-- 124_meal_to_gold.sql
--
-- The Meal level is retired one day after being created (migration 122). Its
-- four members move down to Gold. Jeremy 2026-08-09.
--
-- Mighty Fine Burgers, Rudy's BBQ, The League Kitchen & Tavern and Tony C's
-- Coal Fired Pizza all become Gold sponsors, joining Laurie Flood and W Homes.
-- Gold goes 2 -> 6.
--
-- ⚠️ The Meal tier is DEACTIVATED, not deleted — the project's standing pattern
-- (111 Rudy's, 113 Program Ad). active=false removes it from both /sponsors and
-- the /boosters/sponsor ladder, so it is invisible everywhere while the row,
-- its showcase rank and its sellable=false flag survive for a one-line revert.
-- Deleting would also throw away the only row exercising `sellable`.
--
-- Note this leaves Rudy's, who paid $3,000 for a two-season scoreboard, sitting
-- in the $1,000 Gold tier — below what they actually bought. Migration 123
-- already moved them off Scoreboard "for now" at Jeremy's request; this is a
-- further step in the same direction and is his call, but it is worth being
-- explicit that the site now under-represents that sponsorship.
--
-- Within Gold the six are ordered ALPHABETICALLY, matching how partners are
-- ordered: no ranking is implied among sponsors at the same level.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Gold' and active;
  if n <> 1 then raise exception 'Expected 1 active Gold tier, found %', n; end if;
  select count(*) into n from sponsors s join sponsorship_tiers t on t.id=s.tier_id
   where s.year='2026-27' and t.name='Meal' and s.active;
  if n <> 4 then raise exception 'Expected 4 Meal sponsors to move, found %', n; end if;
end $$;

update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Gold' and active)
where year='2026-27'
  and tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Meal');

update sponsorship_tiers set active = false
where year='2026-27' and name='Meal';

update sponsors set sort_order=1  where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=2  where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='Rudy''s BBQ';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification: Platinum x2, Gold x6, Blue x3; no Meal section anywhere.

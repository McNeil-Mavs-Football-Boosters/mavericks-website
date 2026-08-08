-- 117_rollback.sql
--
-- Reverses 117: removes W Homes, returns Rudy's to a Community Partner, drops
-- the showcase rank column, restores the previous sort_order numbering.
--
-- ⚠️ Dropping showcase_rank_cents makes /sponsors fall back to price ordering,
-- which puts Scoreboard ABOVE Diamond. That is the behaviour 117 existed to fix.

begin;

delete from sponsors where year='2026-27' and name='W Homes Collective';

update sponsors
set kind='community_partner', tier_id=null, sort_order=0
where year='2026-27' and name='Rudy''s BBQ';

update sponsors set sort_order=2 where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=3 where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=4 where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=5 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=6 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=7 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

alter table sponsorship_tiers drop column if exists showcase_rank_cents;

commit;

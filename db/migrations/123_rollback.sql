-- 123_rollback.sql — Rudy's back to Scoreboard; the section reappears by itself.
begin;
update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Scoreboard'),
    sort_order = 1
where year='2026-27' and name='Rudy''s BBQ';
update sponsors set sort_order=2  where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
commit;

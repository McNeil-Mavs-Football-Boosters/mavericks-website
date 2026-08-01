-- 107_sponsor_urls.sql
--
-- Fills in the two website_url values that 106 deliberately left NULL because
-- no URL could be verified at the time. Both supplied by Jeremy and checked:
--
--   capstonecoins.com     200, "Austin Rare Coin Dealer | Ancient, U.S. Gold &
--                         Shipwreck Coins". The storefront brand is Capstone
--                         Coins rather than Capstone Acquisitions, but the site
--                         itself references "Capstone Acquisitions", so it is
--                         the same business -- not a name collision. (The
--                         earlier guess, capstoneacquisitions.com, serves an
--                         empty 114-byte page and is NOT the sponsor's site.)
--   ilovemamabettys.com   200, "Your Favorite Tex-Mex Restaurant in Austin! -
--                         Mama Betty's Tex-Mex".
--
-- Scoped to year 2026-27 so the retired 2025-26 rows are untouched.

begin;

update sponsors
set website_url = 'https://capstonecoins.com'
where year = '2026-27' and name = 'Capstone Acquisitions';

update sponsors
set website_url = 'https://ilovemamabettys.com'
where year = '2026-27' and name = 'Mama Betty''s Tex-Mex';

commit;

-- 045_committees_full_descriptions.sql
-- Update committees with full SE-site descriptions per spec_review.md.
-- Original seed (migration 010) used abbreviated copy; this replaces with
-- the verbatim descriptions from the existing SportsEngine site so the new
-- /boosters/committees page can show recruiting-grade detail per committee.
--
-- Renumbered from spec's 044 because 044 is already taken by
-- 044_reset_sponsors_featured.sql (shipped 2026-05-22).

begin;

update committees set description = 'Maintain football website for communications and notification to parents and players. Maintain Facebook and Twitter accounts. Ongoing throughout school year.' where name = 'Social Media';

update committees set description = 'Coordinate pregame meals for freshman and JV. Discuss menu and price with Sponsor. Identify vendors, solicit bids, coordinate pickup and delivery. Coordinate Varsity parent team dinners. Football season only.' where name = 'Team Meals';

update committees set description = 'Maintain membership list (emails, contact info, current player roster). Collect sign-in sheets from meetings and events. Promote the Booster Club. Ongoing.' where name = 'Membership';

update committees set description = 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events. Monthly report at Booster meeting. Work with Social Media to advertise. Ongoing.' where name = 'Merchandise';

update committees set description = 'Date, location, volunteers for spring and fall parent meetings. Work with Social Media, Merchandise, and Membership committees. Two-time activity.' where name = 'Parent Meetings';

update committees set description = 'Date, time schedule. Cafeteria booking. Vendor bids. Awards coordination with Sponsor. Volunteer coordination for ads, tickets, decorations, senior gifts. One-time activity.' where name = 'Football Banquet';

update committees set description = 'Pool location, volunteers, food donations. Advertise via Social Media. One-time activity.' where name = 'Summer Events';

update committees set description = 'Date with Sponsor and Principal. Coordinate with other booster clubs. Food vendor bids. Tables, volunteers. One-time activity.' where name = 'Meet the Mavs';

update committees set description = 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers. One-time activity.' where name = 'Senior Night';

update committees set description = 'Event date. Business sponsorships. Advertise via Social Media. Application and payment design. Spirit wear order. Volunteers. One-time activity.' where name = 'Tunnel Stampede';

update committees set description = 'Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing.' where name = 'Fundraisers';

commit;

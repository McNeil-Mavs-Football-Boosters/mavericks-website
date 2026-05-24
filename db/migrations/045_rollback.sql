-- 045_rollback.sql
-- Restore the abbreviated committee descriptions from the original seed
-- (migration 010_seed.sql). Schema unchanged; data-only revert.

begin;

update committees set description = 'Maintain football website for communications and notifications. Maintain Facebook accounts promoting a positive image of the program.' where name = 'Social Media';

update committees set description = 'Coordinate pregame meals for freshman and JV players. Coordinate Varsity parent team dinners.' where name = 'Team Meals';

update committees set description = 'Maintain membership list. Collect sign-in sheets from meetings and events. Promote the Booster Club.' where name = 'Membership';

update committees set description = 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events.' where name = 'Merchandise';

update committees set description = 'Date, location, volunteers for spring and fall parent meetings.' where name = 'Parent Meetings';

update committees set description = 'Date, time, venue. Vendor bids. Awards coordination with Sponsor. Volunteer coordination.' where name = 'Football Banquet';

update committees set description = 'Pool location, volunteers, food donations. Advertise via Social Media.' where name = 'Summer Events';

update committees set description = 'Date with Sponsor/Principal. Coordinate with other booster clubs. Food vendor bids.' where name = 'Meet the Mavs';

update committees set description = 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers.' where name = 'Senior Night';

update committees set description = 'Event date. Business sponsorships. Application/payment design. Spirit wear order. Volunteers.' where name = 'Tunnel Stampede';

update committees set description = 'Oversee any board-determined fundraisers. Coordinate with Social Media.' where name = 'Fundraisers';

commit;

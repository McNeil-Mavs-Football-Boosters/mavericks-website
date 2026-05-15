-- Migration 010: Seed data (run after schema creation, before first deploy)

-- Membership tiers for 2026-27 (from Jeremy's actual Google Form)
INSERT INTO membership_tiers (name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label) VALUES
  ('Free Fan Base!', 0, 'Stay in the loop. Newsletters, updates, community.', '["Newsletter access", "Community updates"]'::jsonb, 1, '2026-27', false, false, null),
  ('Game Day!', 2000, 'Show your support on game day.', '["Listed on website (if you opt in)"]'::jsonb, 2, '2026-27', false, false, 'Most Popular'),
  ('Offense ⇄ Defense!', 5000, 'Step up your support.', '["Listed on website (if you opt in)"]'::jsonb, 3, '2026-27', false, false, null),
  ('Blitz!', 10000, 'Get a Mavericks t-shirt.', '["Listed on website (if you opt in)", "1 Booster t-shirt"]'::jsonb, 4, '2026-27', true, false, null),
  ('Touchdown!', 25000, 'Make a real impact.', '["Listed on website (if you opt in)", "2 Booster t-shirts"]'::jsonb, 5, '2026-27', true, true, null),
  ('Playoffs!', 50000, 'Top-tier supporter.', '["Listed on website (if you opt in)", "2 Booster t-shirts", "VIP recognition"]'::jsonb, 6, '2026-27', true, true, null);

-- Sponsorship tiers for 2026-27 (mirroring Stony Point comp; board ratifies)
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, year, badge_label) VALUES
  ('MVP', 500000, 'Top sponsor. Maximum visibility.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement at home games", "Game program: Cover ad", "Streaming banner all games", "6x 30-sec audio commercials per game"]'::jsonb, 1, '2026-27', null),
  ('Diamond', 250000, 'Premium sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "4x 30-sec audio commercials per game"]'::jsonb, 2, '2026-27', null),
  ('Platinum', 150000, 'High-visibility sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "2x 30-sec audio commercials per game"]'::jsonb, 3, '2026-27', 'Recommended'),
  ('Gold', 100000, 'Mid-tier sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Half page", "Streaming recognition"]'::jsonb, 4, '2026-27', null),
  ('Blue', 50000, 'Community sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Quarter page", "Streaming recognition"]'::jsonb, 5, '2026-27', null);

-- Board members for 2026-27 (from booster_club_info.md)
INSERT INTO board_members (name, role, sort_order, year) VALUES
  ('Carol Glinski', 'President', 1, '2026-27'),
  ('Chevon Williams', 'Treasurer', 2, '2026-27'),
  ('Ashley Olson', 'Co-Treasurer', 3, '2026-27'),
  ('Kendra Jalbert', 'VP of Fundraising', 4, '2026-27'),
  ('Shannon Schoepflin', 'VP of Social Events', 5, '2026-27'),
  ('Sylvia Brito', 'VP of Merchandise', 6, '2026-27'),
  ('Jeremy Vest', 'Secretary', 7, '2026-27'),
  ('Debby Mata', 'Communications & Membership Support', 8, '2026-27'),
  ('Monica Woods', 'Social Events Support', 9, '2026-27');

-- Committees (from old SE site, 11 committees)
INSERT INTO committees (name, description, cadence, sort_order) VALUES
  ('Social Media', 'Maintain football website for communications and notifications. Maintain Facebook accounts promoting a positive image of the program.', 'ongoing', 1),
  ('Team Meals', 'Coordinate pregame meals for freshman and JV players. Coordinate Varsity parent team dinners.', 'seasonal', 2),
  ('Membership', 'Maintain membership list. Collect sign-in sheets from meetings and events. Promote the Booster Club.', 'ongoing', 3),
  ('Merchandise', 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events.', 'ongoing', 4),
  ('Parent Meetings', 'Date, location, volunteers for spring and fall parent meetings.', 'seasonal', 5),
  ('Football Banquet', 'Date, time, venue. Vendor bids. Awards coordination with Sponsor. Volunteer coordination.', 'one_time', 6),
  ('Summer Events', 'Pool location, volunteers, food donations. Advertise via Social Media.', 'one_time', 7),
  ('Meet the Mavs', 'Date with Sponsor/Principal. Coordinate with other booster clubs. Food vendor bids.', 'one_time', 8),
  ('Senior Night', 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers.', 'one_time', 9),
  ('Tunnel Stampede', 'Event date. Business sponsorships. Application/payment design. Spirit wear order. Volunteers.', 'one_time', 10),
  ('Fundraisers', 'Oversee any board-determined fundraisers. Coordinate with Social Media.', 'ongoing', 11);

-- site_settings already inserted via INSERT...ON CONFLICT in the table definition (005_settings.sql)

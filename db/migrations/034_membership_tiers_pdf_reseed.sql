-- Migration 034: Reseed membership_tiers for 2026-27 to match the
-- board-ratified PDF (docs/2026 - 2027 Membership - McNeil HS Football
-- Boosters.pdf). The seed in migration 010 predates the PDF and has
-- only 6 tiers with placeholder copy; this replaces it with the 7
-- canonical tiers.
--
-- Spec: docs/specs/boosters_join_spec.md (Slice 1 / Turn 1).
-- Filename note: spec said "030" but 030 is taken by the year-split
-- migration. This is 034 (next free slot).
--
-- DELETE (not TRUNCATE) so any rows from other years are preserved.
-- year stays '2026-27' to match the PDF + current_board_year; the
-- /boosters/join page query in Turn 2 must read current_board_year
-- (not current_year, which now governs football data).

BEGIN;

DELETE FROM membership_tiers WHERE year = '2026-27';

INSERT INTO membership_tiers
  (name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label, active)
VALUES
  ('Free Fan Base!', 0, 'Join Mav Nation.',
   '["Receive the Mavs Football Booster newsletter and important Mavs updates!"]'::jsonb,
   1, '2026-27', false, false, null, true),
  ('Game Day!', 2000, 'Friday nights, Mavs colors.',
   '["Mavs Football Car Decal"]'::jsonb,
   2, '2026-27', false, false, 'Most Popular', true),
  ('Offense ⇄ Defense!', 5000, 'Back both sides of the ball.',
   '["1 Mavs Football Game Day Fan or Bell", "1 Exclusive Booster Car Decal"]'::jsonb,
   3, '2026-27', false, false, null, true),
  ('Blitz!', 10000, 'Bring the pressure.',
   '["1 Exclusive Booster T-Shirt Voucher", "2 Mavs Football Car Decals"]'::jsonb,
   4, '2026-27', true, false, 'Best Value', true),
  ('Touchdown!', 25000, 'Six points for the program.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals"]'::jsonb,
   5, '2026-27', true, true, 'Recommended', true),
  ('Playoffs!', 50000, 'Push deep into November.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games"]'::jsonb,
   6, '2026-27', true, true, null, true),
  ('Championship!', 100000, 'Go all in for the ring.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games", "Premier Parking Space at All Home Games"]'::jsonb,
   7, '2026-27', true, true, null, true);

COMMIT;

-- 074_sponsorship_levels_overhaul.sql
--
-- Sponsorship page content overhaul per Kendra's spec (2026-07-17), Phase A
-- (copy / pricing / data only — no inquiry form yet).
--
-- Restructures sponsorship_tiers into 6 BASE levels + 2 ADD-ONS:
--   Base:    Blue $500, Gold $1,000, Platinum $1,500, Diamond $2,500,
--            MVP $5,000, Custom (flexible).
--   Add-ons: Tunnel $350 (per season), Scoreboard $3,000 (two seasons).
--
-- Schema additions (approved 2026-07-20 — the "3 explicit columns" model):
--   is_addon       — true for Tunnel/Scoreboard so the page renders them in
--                    a separate Add-Ons section (selectable alone or with a base).
--   price_flexible — true for Custom; the card shows "Custom" instead of "$0".
--   term_label     — "per season" / "two seasons"; rendered on a price-adjacent
--                    line so the term stays OUT of the benefit bullets.
-- All three are backward-compatible (defaults keep existing rows unchanged).
--
-- Also: every "Game program" perk is removed (the base perk arrays are rewritten
-- wholesale below). Benefit bullets are fully enumerated per tier — commercial
-- counts change per tier (2 -> 4 -> 6), so cumulative "everything in X" phrasing
-- would misread as additive.
--
-- Operates on year 2025-26 (site_settings.current_year; the year the sponsor
-- pages read). Idempotent: base tiers UPDATE in place, add-ons INSERT-if-absent.

BEGIN;

-- 1. Schema: three explicit columns.
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS is_addon boolean NOT NULL DEFAULT false;
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS price_flexible boolean NOT NULL DEFAULT false;
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS term_label text;

-- 2. Base tiers (rewrite perks, confirm price, set term/sort, clear add-on flags).
UPDATE sponsorship_tiers SET
  price_cents = 50000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 1
WHERE year = '2025-26' AND name = 'Blue';

UPDATE sponsorship_tiers SET
  price_cents = 100000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 2
WHERE year = '2025-26' AND name = 'Gold';

UPDATE sponsorship_tiers SET
  price_cents = 150000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive", "Two 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = 'Recommended',
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 3
WHERE year = '2025-26' AND name = 'Platinum';

UPDATE sponsorship_tiers SET
  price_cents = 250000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive", "Streaming banner at all games", "Four 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 4
WHERE year = '2025-26' AND name = 'Diamond';

UPDATE sponsorship_tiers SET
  price_cents = 500000,
  perks = '["Maximum visibility across the McNeil Football program", "Logo and link on the McNeil Mavericks website", "Field sign at games and business sign on McNeil Drive", "Social media and newsletter promotion", "Public address announcement at home games", "Streaming banner at all games", "Six 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 5
WHERE year = '2025-26' AND name = 'MVP';

-- 3. Custom (flexible base level). INSERT if absent.
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label)
SELECT 'Custom', 0,
  E'Flexible sponsorship\n\nCustom packages and in-kind ideas are encouraged. Tell us what your business is looking for and we''ll build a sponsorship that fits.',
  '[]'::jsonb, 6, true, '2025-26', NULL, false, true, 'per season'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Custom'
);

-- 4. Tunnel add-on ($350 per season). INSERT if absent.
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label)
SELECT 'Tunnel', 35000,
  E'Homecoming Tunnel Stampede\n\nYour business recognized as the sponsor of the Homecoming Tunnel Stampede as the Mavs take the field.',
  '[]'::jsonb, 7, true, '2025-26', NULL, true, false, 'per season'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Tunnel'
);

-- 5. Scoreboard add-on ($3,000 for two seasons). Row exists; UPDATE in place.
--    Venue clarification required; no payment/"paid upfront" language.
UPDATE sponsorship_tiers SET
  price_cents = 300000,
  perks = '[]'::jsonb,
  description = E'Scoreboard logo\n\nYour logo on the McNeil Stadium scoreboard for two full seasons. The scoreboard is at McNeil Stadium, and varsity home games are played at KRAC, so this exposure is primarily at freshman and JV games played at McNeil Stadium.',
  badge_label = NULL,
  is_addon = true,
  price_flexible = false,
  term_label = 'two seasons',
  sort_order = 8
WHERE year = '2025-26' AND name = 'Scoreboard';

COMMIT;

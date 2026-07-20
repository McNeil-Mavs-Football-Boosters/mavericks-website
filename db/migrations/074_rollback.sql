-- 074_rollback.sql
-- Reverses 074_sponsorship_levels_overhaul.sql.
--
-- Restores the pre-overhaul year 2025-26 tier rows (perks/prices/sort_order/
-- badges as they were), deletes the Custom + Tunnel rows this migration added,
-- and drops the three columns. Scoreboard goes back to $5,000 with its old
-- "Premier · 2 Years" badge and empty perks.

BEGIN;

DELETE FROM sponsorship_tiers WHERE year = '2025-26' AND name IN ('Custom', 'Tunnel');

UPDATE sponsorship_tiers SET
  price_cents = 500000,
  perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement at home games", "Game program: Cover ad", "Streaming banner all games", "6x 30-sec audio commercials per game"]'::jsonb,
  badge_label = NULL,
  sort_order = 1
WHERE year = '2025-26' AND name = 'MVP';

UPDATE sponsorship_tiers SET
  price_cents = 250000,
  perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "4x 30-sec audio commercials per game"]'::jsonb,
  badge_label = NULL,
  sort_order = 2
WHERE year = '2025-26' AND name = 'Diamond';

UPDATE sponsorship_tiers SET
  price_cents = 150000,
  perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "2x 30-sec audio commercials per game"]'::jsonb,
  badge_label = 'Recommended',
  sort_order = 3
WHERE year = '2025-26' AND name = 'Platinum';

UPDATE sponsorship_tiers SET
  price_cents = 100000,
  perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program"]'::jsonb,
  badge_label = NULL,
  sort_order = 4
WHERE year = '2025-26' AND name = 'Gold';

UPDATE sponsorship_tiers SET
  price_cents = 50000,
  perks = '["Logo + link on website", "Social + newsletter promo", "PA announcement"]'::jsonb,
  badge_label = NULL,
  sort_order = 5
WHERE year = '2025-26' AND name = 'Blue';

UPDATE sponsorship_tiers SET
  price_cents = 500000,
  perks = '[]'::jsonb,
  description = NULL,
  badge_label = 'Premier · 2 Years',
  sort_order = 6
WHERE year = '2025-26' AND name = 'Scoreboard';

ALTER TABLE sponsorship_tiers DROP COLUMN IF EXISTS term_label;
ALTER TABLE sponsorship_tiers DROP COLUMN IF EXISTS price_flexible;
ALTER TABLE sponsorship_tiers DROP COLUMN IF EXISTS is_addon;

COMMIT;

-- 067_add_scoreboard_tier.sql
--
-- Adds a 6th sponsorship tier for 2025-26: "Scoreboard" ($5,000, 2-year commitment).
-- Puts the sponsor's logo on the McNeil HS stadium scoreboard for two full seasons.
-- Unlike the other tiers it carries a short summary instead of a perk list: perks is
-- left empty ('[]'). The description holds two paragraphs separated by a blank line —
-- the first ("Two Years") renders as the gray-italic subtitle under the name (matching
-- MVP's "Top sponsor..." tagline), the rest renders as the card body. badge_label
-- highlights the premier / two-year nature without clashing with the $5,000 MVP tier.
--
-- sort_order = 6 (after Blue=5) so the price-based 3-over-3 card split on /boosters/sponsor
-- puts Scoreboard last in the large bottom row (Diamond, MVP, Scoreboard).
--
-- Idempotent: guarded by NOT EXISTS.

BEGIN;

INSERT INTO sponsorship_tiers (year, name, price_cents, description, perks, sort_order, badge_label, active)
SELECT '2025-26', 'Scoreboard', 500000,
       'Two Years

Your business logo on the McNeil HS stadium scoreboard for two full seasons — front and center for every fan at every home game. Our most visible, longest-running sponsorship.',
       '[]'::jsonb,
       6, 'Premier · 2 Years', true
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Scoreboard'
);

COMMIT;

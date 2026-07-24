-- 086_sponsor_program_ad_addon.sql
--
-- Adds a "Program Ad" add-on to the sponsorship page with a tiered price range
-- ($100 quarter page / $150 half / $250 full) and a July 31 commit deadline.
--
-- Schema: adds price_display (nullable text). The sponsor card renders a single
-- computed "$X" price; price_display lets a row show a custom string instead
-- (here the "$100–$250" range). NULL on every existing row = unchanged behavior.
--
-- The deadline rides in badge_label ("Commit by July 31" green pill); the tier
-- breakdown is in the summary description. is_addon=true so it renders in the
-- Add-Ons section. Seeded at year 2025-26 (current_year, what the page reads).
--
-- Idempotent: column IF NOT EXISTS; INSERT-if-absent on (year, name).

BEGIN;

ALTER TABLE sponsorship_tiers ADD COLUMN IF NOT EXISTS price_display text;

INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label, price_display)
SELECT 'Program Ad', 10000,
  $desc$Ad in the football program

Reserve space in this season's football program: 1/4 page (logo) $100, 1/2 page $150, or full page $250. Commit by July 31 to make this season's program.$desc$,
  '[]'::jsonb, 9, true, '2025-26', 'Commit by July 31', true, false, NULL, '$100–$250'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Program Ad'
);

COMMIT;

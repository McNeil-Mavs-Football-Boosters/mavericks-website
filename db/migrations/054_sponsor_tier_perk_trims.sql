-- 054_sponsor_tier_perk_trims.sql
-- Trim sponsorship tier perks per Jeremy 2026-05-29.
--   Blue ($500):     drop "Sign at field", "Game program: Quarter page", "Streaming recognition".
--   Gold ($1000):    "Game program: Half page" -> "Game program"; drop "Streaming recognition".
--   Platinum ($1500): drop "Streaming banner all games".
-- Diamond + MVP untouched (streaming banner remains only on those two tiers).
-- Full-array replacement scoped by name + year so re-running is idempotent.

begin;

update sponsorship_tiers
set perks = '["Logo + link on website", "Social + newsletter promo", "PA announcement"]'::jsonb
where name = 'Blue' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program"]'::jsonb
where name = 'Gold' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "2x 30-sec audio commercials per game"]'::jsonb
where name = 'Platinum' and year = '2025-26';

commit;

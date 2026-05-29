-- 054_rollback.sql
-- Restore the pre-054 sponsorship tier perks for Blue / Gold / Platinum (2025-26).

begin;

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Quarter page", "Streaming recognition"]'::jsonb
where name = 'Blue' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Half page", "Streaming recognition"]'::jsonb
where name = 'Gold' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "2x 30-sec audio commercials per game"]'::jsonb
where name = 'Platinum' and year = '2025-26';

commit;

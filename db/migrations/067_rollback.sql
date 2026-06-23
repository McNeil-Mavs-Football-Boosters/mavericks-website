-- 067_rollback.sql
-- Reverses 067_add_scoreboard_tier.sql.

BEGIN;

DELETE FROM sponsorship_tiers
WHERE year = '2025-26' AND name = 'Scoreboard';

COMMIT;

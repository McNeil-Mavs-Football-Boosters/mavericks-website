-- Migration 095: decouple the displayed ROSTER year from current_year, and
-- advance it to 2026-27 so the stale 2025-26 rosters stop showing.
-- Same pattern as current_board_year (030), current_coaches_year (055),
-- current_schedule_year (056).
--
-- Why not just flip current_year: it still governs sponsors, sponsorship_tiers
-- (both /sponsors and /boosters/sponsor) and the homepage sponsor strip, all
-- seeded as 2025-26. Flipping it would blank those pages.
--
-- The empty 2026-27 roster rows already exist (varsity, jv, freshman Blue +
-- Green; 0 players, no pdf_storage_path), so the roster pages render their
-- "Coming Soon" empty state and the Print View buttons drop off on their own.
-- The 2025-26 rosters + players are left intact as history, just unreachable.
-- When the real 2026-27 rosters arrive, seed players into those rows -- no
-- flag flip and no code change needed.
BEGIN;
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_roster_year text NOT NULL DEFAULT '2025-26';
UPDATE site_settings SET current_roster_year = '2026-27' WHERE id = 1;
COMMIT;

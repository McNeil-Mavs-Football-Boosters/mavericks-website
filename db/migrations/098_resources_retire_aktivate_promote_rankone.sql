-- 098_resources_retire_aktivate_promote_rankone.sql
--
-- Fixes the RankOne-vs-Aktivate contradiction surfaced 2026-07-28 when Coach
-- Gardner's ONE MAV deck was posted (migration 097). Deck slide 9 sends
-- parents to RankOne.com and requires GREEN status before Aug 3, while
-- /resources still told them Aktivate had "replaced the old RankOne system."
--
-- WHY AKTIVATE IS THE STALE ONE (traced, not guessed):
--   * The Aktivate row came from migration 018 — the ORIGINAL SportsEngine
--     content port (May 2026). It was seeded from old-site copy and never
--     revisited.
--   * Migration 035 (2026-05-19) already repointed "RRISD Athletic Forms" to
--     https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx because
--     Jeremy confirmed Rank One was the real forms portal.
--   * Migration 071 (July 2026 events) embeds that same Rank One link for both
--     equipment pickups, with the "all green" requirement.
--   * Coach's 7/27/2026 deck says Rank One, and Jeremy + Karen confirmed from
--     what they're actually seeing as parents in 2026-27.
-- So two of three site surfaces plus the coaching staff all say Rank One. The
-- Aktivate row was the only holdout.
--
-- WHAT THIS DOES:
--   1. Deactivates the Aktivate row (active=false rather than DELETE, so the
--      history stays visible and the rollback is trivial). If RRISD ever does
--      move to Aktivate, flip it back rather than reseeding.
--   2. Promotes the existing (already-correct-URL) "RRISD Athletic Forms" row
--      into the vacated top slot (sort_order 3 → 1) and relabels it
--      "RRISD Athletic Forms (Rank One)" so parents arriving from Coach's deck
--      recognize the name he used.
--   3. Rewrites its description to carry the actual requirement — forms
--      complete and GREEN before an athlete can practice or be issued
--      equipment — which is the single most actionable line in the deck.
--
-- Deliberately NOT creating a second row for Rank One: the RRISD Athletic
-- Forms row already points at the exact same URL, and two entries to one
-- destination is how parents get confused. One row, one destination.
--
-- No date (Aug 3) in the description on purpose — /events + /schedule carry
-- dates; this row states the standing requirement so it doesn't go stale.

BEGIN;

-- 1. Retire the stale Aktivate row.
UPDATE resource_links
SET active = false
WHERE section = 'registration_forms'
  AND label = 'Aktivate (Athletic Registration)';

-- 2 + 3. Promote, relabel, and rewrite the Rank One row.
UPDATE resource_links
SET label = 'RRISD Athletic Forms (Rank One)',
    description = 'Complete every required athletic form in Rank One. Athletes must be "all green" before they can practice, compete, or be issued equipment.',
    sort_order = 1
WHERE section = 'registration_forms'
  AND label = 'RRISD Athletic Forms';

COMMIT;

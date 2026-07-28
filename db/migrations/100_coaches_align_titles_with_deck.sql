-- 100_coaches_align_titles_with_deck.sql
--
-- Aligns 2026-27 coach titles/positions with Coach Gardner's ONE MAV Parent &
-- Athlete Meeting deck (7/27/2026, slide 2). Jeremy 2026-07-28: "update titles
-- and positions per the deck — feels like coach would be more correct than us."
-- The coaching staff is the coaching staff's own source of truth.
--
-- FIRST 100-NUMBERED MIGRATION. The documented `db/apply_all.sql` regeneration
-- loop globbed `db/migrations/0*.sql`, which does NOT match `100_*.sql` — this
-- file would have silently dropped out of the bundle with no error. The glob is
-- corrected to `db/migrations/[0-9]*.sql` in docs/CLAUDE.md in the same commit.
--
-- THREE CHANGES (the other 8 coaches already matched the deck):
--
-- 1. Jerry Gardner: "Head Coach and Athletic Director"
--                -> "Athletic Coordinator / Head Football Coach"
--    Our row had him as Athletic DIRECTOR, which is Jeff Cheatham's job — the
--    deck's Administration column lists Cheatham as AD and Gardner as Athletic
--    Coordinator. Using the deck's own slide-1 expansion of "AC" rather than
--    publishing the abbreviation.
--
-- 2. Douglas Wallin: "Defensive Line Coach" -> "Linebackers Coach"
--    A real POSITION change, not wording. Migration 093 had him as the third
--    DL coach alongside Debose + Edwards; the deck moves him to linebackers,
--    leaving Debose + Edwards on the line. This is the change most worth
--    getting right — it was wrong on a public page.
--
-- 3. Barrett Matthews: "Special Teams & Pass Game Coordinator"
--                   -> "Special Teams Coordinator / Receivers"
--
-- STYLE: the deck lists bare position rooms ("Linebackers", "Running Backs");
-- the site's house style suffixes them with "Coach" ("Running Backs Coach") and
-- all 8 unchanged rows already read that way. Kept the suffix so this migration
-- changes substance, not typography. Coordinator titles are taken verbatim.
--
-- NOT CHANGED, ON PURPOSE:
--   * "Michael Hale" (deck says "Jake Hale"). A first name is neither a title
--     nor a position, and this repo has precedent for preferring full names
--     over what a document says — migration 039 deliberately set "Douglas
--     Wallin" where everything else said "Doug". Michael is plausibly legal
--     with Jake as the known-as. Awaiting Coach Gardner's answer; tracked in
--     followups.md. Same reason "Doug Wallin" stays "Douglas Wallin" here.
--   * sort_order. Wallin stays at 10, so on /coaches he now renders between
--     Matthews (6) and the two DL coaches (15, 16) — linebackers before
--     defensive line. Harmless; regroup later if the ordering ever matters.

BEGIN;

UPDATE coaches
SET role = 'Athletic Coordinator / Head Football Coach'
WHERE year = '2026-27' AND name = 'Jerry Gardner';

UPDATE coaches
SET role = 'Linebackers Coach'
WHERE year = '2026-27' AND name = 'Douglas Wallin';

UPDATE coaches
SET role = 'Special Teams Coordinator / Receivers'
WHERE year = '2026-27' AND name = 'Barrett Matthews';

COMMIT;

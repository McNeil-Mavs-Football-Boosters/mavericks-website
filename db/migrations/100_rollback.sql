-- 100_rollback.sql
-- Reverses 100_coaches_align_titles_with_deck.sql, restoring the pre-deck
-- 2026-27 roles (Gardner per migration 018-era seed, Wallin per 039/093,
-- Matthews per the original coaches seed).

BEGIN;

UPDATE coaches
SET role = 'Head Coach and Athletic Director'
WHERE year = '2026-27' AND name = 'Jerry Gardner';

UPDATE coaches
SET role = 'Defensive Line Coach'
WHERE year = '2026-27' AND name = 'Douglas Wallin';

UPDATE coaches
SET role = 'Special Teams & Pass Game Coordinator'
WHERE year = '2026-27' AND name = 'Barrett Matthews';

COMMIT;

-- 099_resources_retire_uil_forms.sql
--
-- Retires the "UIL Forms" row on /resources (Forms & Links → Registration &
-- Forms). Jeremy 2026-07-28: not needed either — everything an athlete has to
-- sign is handled inside the Rank One packet, so a separate link to
-- uiltexas.org/athletics/forms sends parents to a generic state-level page
-- they have no reason to touch.
--
-- Same pattern as migration 098's Aktivate retirement: active=false, not
-- DELETE, so this is one flag flip to restore.
--
-- Registration & Forms is left with two active rows:
--   1  RRISD Athletic Forms (Rank One)
--   4  Game-Day Meal Program (Parent Payment)
-- Gap in sort_order values is harmless (the page orders by sort_order, it
-- doesn't require them to be contiguous), and leaving 4 alone keeps this
-- migration to a single field change.

BEGIN;

UPDATE resource_links
SET active = false
WHERE section = 'registration_forms'
  AND label = 'UIL Forms';

COMMIT;

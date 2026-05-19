-- Migration 035: Fix RRISD Athletic Forms URL.
--
-- The /resources page card pointed to https://roundrockisd.org/athletics
-- (a landing page that requires further clicks). Jeremy 2026-05-19: the
-- direct deep link is the Rank One forms portal. Update the resource_links
-- row in place.
--
-- Idempotent: UPDATE matches on label, sets the URL. No-op on re-run.

BEGIN;

UPDATE resource_links
SET url = 'https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx'
WHERE label = 'RRISD Athletic Forms';

COMMIT;

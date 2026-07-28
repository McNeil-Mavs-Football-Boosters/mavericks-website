-- 098_rollback.sql
-- Reverses 098_resources_retire_aktivate_promote_rankone.sql: reactivates the
-- Aktivate row and restores the Rank One row's original label, description,
-- and sort_order (3) as set by migrations 018 + 035.

BEGIN;

UPDATE resource_links
SET active = true
WHERE section = 'registration_forms'
  AND label = 'Aktivate (Athletic Registration)';

UPDATE resource_links
SET label = 'RRISD Athletic Forms',
    description = 'Round Rock ISD athletic department forms and policies.',
    sort_order = 3
WHERE section = 'registration_forms'
  AND label = 'RRISD Athletic Forms (Rank One)';

COMMIT;

-- 083_rollback.sql
-- Restores the prior pool party description.

BEGIN;

UPDATE events SET
  description = $desc$Join us for the 2026 Mavs Football Pool Party. All teams and parents are welcome, and the Mavs coaching staff and members of the booster club will be there. The booster club provides the mains; parents are asked to donate drinks, desserts, fruit/veggies, sides, and chips. Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

-- 083_pool_party_description_update.sql
--
-- Softens the pool party food ask (donate "if you're able" rather than
-- "asked to donate") and points readers to the event link for directions +
-- the food sign-up (the detail page's Get directions + Sign Up buttons).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  description = $desc$Join us for the 2026 Mavs Football Pool Party! All teams and families are welcome, and the Mavs coaching staff and booster club will be there. The booster club provides the main dishes, and if you're able, we'd love help with drinks, desserts, fruit and veggies, sides, and chips. Click the McNeil Mavs Pool Party link for directions and to sign up to bring food. Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

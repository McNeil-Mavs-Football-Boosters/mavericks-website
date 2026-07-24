-- 085_rollback.sql
-- Reverses 085: Sign Up back to the food SignUpGenius + the prior "bring food" copy.

BEGIN;

UPDATE events SET
  signup_url = 'https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-64853046-2026?useFullSite=true#/',
  description = $desc$Join us for the 2026 Mavs Football Pool Party! All teams and families are welcome, and the Mavs coaching staff and booster club will be there. The booster club provides the main dishes, and if you're able, we'd love help with drinks, desserts, fruit and veggies, sides, and chips. Click the McNeil Mavs Pool Party link for directions and to sign up to bring food. Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

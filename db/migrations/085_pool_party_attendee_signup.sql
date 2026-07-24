-- 085_pool_party_attendee_signup.sql
--
-- Swaps the pool party event's Sign Up from the food SignUpGenius to the new
-- attendee RSVP Google Form ("McNeil Mavs Football Pool Party — Sign-Up"), and
-- updates the copy from "sign up to bring food" to "sign up to attend". The
-- food SignUpGenius is still reachable via a link inside the attendee form.
-- Uses the clean /viewform link (the ?edit_requested=true param was stripped).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://docs.google.com/forms/d/12oQleUb7c3vbcd6UjoWfDPivsC0icTZ3L4tg9yq-NS4/viewform',
  description = $desc$Join us for the 2026 Mavs Football Pool Party! All teams and families are welcome, and the Mavs coaching staff and booster club will be there. The booster club provides the main dishes, and if you're able, we'd love help with drinks, desserts, fruit and veggies, sides, and chips. Click the McNeil Mavs Pool Party link for directions and to sign up to attend (there's a food sign-up in the form too). Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

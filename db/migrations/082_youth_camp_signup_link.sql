-- 082_youth_camp_signup_link.sql
--
-- Youth Football Camp (Fri Jul 24 2026, slug youth-football-camp-2026,
-- "7th-9th Grade Football Camp") registration link.
--   * Add the camp registration Google Form as signup_url — the event detail
--     page renders it as a "Sign Up →" button.
--   * The booster supplied the private editor link (…/edit); this stores the
--     PUBLIC responder link (…/viewform) instead, which was verified to serve
--     a fillable form with no login required.
-- Date/time/location unchanged.
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://docs.google.com/forms/d/1Qno3ycvDrSzDgmySCiX0WxOJoX4G5PTz81WCX6cj_hc/viewform'
WHERE slug = 'youth-football-camp-2026';

COMMIT;

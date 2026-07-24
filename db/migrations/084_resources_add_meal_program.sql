-- 084_resources_add_meal_program.sql
--
-- Adds the "2026 Game Day Meal Program - Parent Payment Form" to /resources
-- (Forms & Links) under Registration & Forms, sort_order 4 (after RRISD Athletic
-- Forms). Uses the public /viewform responder link (NOT the /edit editor link).
-- The form is a Google Form with a payment add-on; the Stripe checkout runs
-- after submit. icon_hint='form' (ClipboardList), matching the mailing-list row.
--
-- Idempotent: INSERT-if-absent on (section, label).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
SELECT 'registration_forms',
       'Game-Day Meal Program (Parent Payment)',
       'https://docs.google.com/forms/d/1jFCsISKk-BIBwgl-Hp-62-bZzTHKg-wqX5Fa7Q6j2JM/viewform',
       'Sign up and contribute to your athlete''s game-day meals for the 2026 season.',
       'form',
       4,
       true
WHERE NOT EXISTS (
  SELECT 1 FROM resource_links
  WHERE section = 'registration_forms' AND label = 'Game-Day Meal Program (Parent Payment)'
);

COMMIT;

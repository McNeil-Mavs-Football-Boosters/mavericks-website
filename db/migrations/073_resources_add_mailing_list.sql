-- 073_resources_add_mailing_list.sql
--
-- Adds "Join Our Mailing List" to /resources (Forms & Links) under
-- News & Communications, ABOVE MavMail (MavMail is sort_order=-2, so this
-- row takes -3). Links to the booster membership Google Form (the same URL
-- as BOOSTER_FORM_URL in lib/constants.ts) — Jeremy 2026-07-20: the
-- membership form is the email-collection channel for club communications.
-- icon_hint='form' (ClipboardList) rather than 'mail' so it doesn't
-- duplicate MavMail's mail icon directly below it.
--
-- The same link ships in the site footer (code change, Footer.tsx) with
-- identical "Join Our Mailing List" label.

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'communications',
  'Join Our Mailing List',
  'https://docs.google.com/forms/d/e/1FAIpQLSfJXyssXItMv8EUU3FHkPqMo_9DGpReNlUq283NimBwa-rx1Q/viewform',
  'Get booster club news, game-day updates, and volunteer opportunities by email.',
  'form',
  -3,
  true
);

COMMIT;

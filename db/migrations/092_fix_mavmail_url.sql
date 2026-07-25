-- 092_fix_mavmail_url.sql
--
-- The MavMail resource link pointed to a single dated newsletter issue
-- (mavmail-sunday-may-24-2026), which RRISD has since removed (HTTP 410 Gone).
-- RRISD only publishes MavMail as rotating per-issue URLs (edurooms /engage/…,
-- Smore per-issue codes) with no stable "latest" permalink, so any dated link
-- breaks weekly. Point it instead at the McNeil HS Live Feed, which always
-- surfaces the current MavMail and does not rotate. Idempotent; matched by
-- label + section.

BEGIN;

UPDATE resource_links
SET url = 'https://mcneil.roundrockisd.org/o/mcneil/live-feed'
WHERE section = 'communications'
  AND label = 'MavMail';

COMMIT;

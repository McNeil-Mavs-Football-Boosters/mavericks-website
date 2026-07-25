-- 092_rollback.sql
-- Reverses 092_fix_mavmail_url.sql: restores the prior (dead) dated MavMail URL.

BEGIN;

UPDATE resource_links
SET url = 'https://roundrockisd.edurooms.com/newsletters/mcneil-high-school/newsletters/mavmail-sunday-may-24-2026'
WHERE section = 'communications'
  AND label = 'MavMail';

COMMIT;

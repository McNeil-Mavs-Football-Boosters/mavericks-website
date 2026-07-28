-- 099_rollback.sql
-- Reverses 099_resources_retire_uil_forms.sql by reactivating the UIL Forms
-- row. Its label, url, description, and sort_order (2) were never changed.

BEGIN;

UPDATE resource_links
SET active = true
WHERE section = 'registration_forms'
  AND label = 'UIL Forms';

COMMIT;

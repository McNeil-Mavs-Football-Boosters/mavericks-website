-- 110_rollback.sql
-- Reverses 110: clears the two photo URLs. Leaves the bucket objects in place
-- (same convention as 097_rollback).

BEGIN;

UPDATE coaches
SET photo_url = NULL
WHERE year = '2026-27' AND name IN ('Thomas Umberger', 'Devonte Jones');

COMMIT;

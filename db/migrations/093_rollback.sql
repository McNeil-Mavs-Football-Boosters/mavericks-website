-- 093_rollback.sql
-- Reverses 093: removes Nick Edwards and clears the three added photo URLs.

BEGIN;

DELETE FROM coaches WHERE year = '2026-27' AND name = 'Nick Edwards';

UPDATE coaches
SET photo_url = NULL
WHERE year = '2026-27' AND name IN ('Alexander Gillis', 'Barrett Matthews');

COMMIT;

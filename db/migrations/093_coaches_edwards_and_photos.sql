-- 093_coaches_edwards_and_photos.sql
--
-- Adds new Defensive Line Coach Nick Edwards (2026-27) and sets head-shot photos
-- for Gillis, Matthews, and Edwards (faces cropped from their "Welcome to Mav
-- Nation" graphics, uploaded to the coach-photos storage bucket).
-- Per Jeremy (2026-07-26): the two existing "Defensive Line Coach" rows (Wallin,
-- Debose) stay; Edwards is added alongside them, no replacements. Edwards sorts
-- at 16 to group with the other DL coaches (Wallin 10, Debose 15). Idempotent.

BEGIN;

INSERT INTO coaches (year, name, role, role_category, sort_order, photo_url, active)
SELECT '2026-27', 'Nick Edwards', 'Defensive Line Coach', 'position_coach', 16,
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachEdwardsHead.jpg',
       true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Nick Edwards'
);

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachGillisHead.jpg'
WHERE year = '2026-27' AND name = 'Alexander Gillis';

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachMatthewsHead.jpg'
WHERE year = '2026-27' AND name = 'Barrett Matthews';

COMMIT;

-- 062_coaches_teaching_roles_and_debose.sql
--
-- Coaches page updates (2026-27):
--   * New nullable column `teaching_role` holds each coach's RRISD teaching title
--     (e.g. "Social Studies Teacher"). Kept separate from `role` (the football
--     title) and from `bio` (markdown paragraph — Gardner has a real bio; the
--     other coaches don't). The card renders it as a small line under `role`.
--     "Athletics" is dropped from the RRISD directory phrasing as redundant on a
--     coaches page.
--   * Douglas Wallin: add email + teaching_role. Football role unchanged.
--   * Michael Hale: add teaching_role. Email already present.
--   * Reginal Debose: new Defensive Line Coach (position_coach), same group as
--     Wallin.
--   * Jerry Gardner: add email (no teaching_role).
--   * Photos for Wallin, Hale, Debose live in the coach-photos bucket; photo_url
--     stores the full public URL (same convention as Gardner's row).
--
-- Idempotent: column add is IF NOT EXISTS; the INSERT is guarded by NOT EXISTS.

BEGIN;

ALTER TABLE coaches ADD COLUMN IF NOT EXISTS teaching_role text;

-- Jerry Gardner — add email (no teaching_role; he is Head Coach / Athletic Director).
UPDATE coaches
SET email = 'jerry_gardner@roundrockisd.org'
WHERE year = '2026-27' AND name = 'Jerry Gardner';

-- Douglas Wallin — add email + teaching subject + photo.
UPDATE coaches
SET email = 'Douglas_Wallin@roundrockisd.org',
    teaching_role = 'Social Studies Teacher',
    photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWallinHead.jpg'
WHERE year = '2026-27' AND name = 'Douglas Wallin';

-- Michael Hale — add teaching subject + photo (email already set).
UPDATE coaches
SET teaching_role = 'Physical Education Teacher',
    photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachHaleHead.jpg'
WHERE year = '2026-27' AND name = 'Michael Hale';

-- Reginal Debose — new Defensive Line Coach.
INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Reginal Debose', 'Defensive Line Coach', 'position_coach',
       'reginal_debose@roundrockisd.org', 'Special Education Teacher',
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachDeboseHead.jpg',
       15, true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Reginal Debose'
);

COMMIT;

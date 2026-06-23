-- 066_coach_justin_ward.sql
--
-- Coaches page update (2026-27):
--   * Justin Ward: new Receiver Coach (position_coach), same group as Debose/Wallin.
--     teaching_role drops "& Athletics" per the 062 RRISD-directory convention.
--     sort_order = 20 (next position_coach slot after Debose's 15).
--   * Photo lives in the coach-photos bucket as CoachWard.jpg (verified the exact
--     object name + casing against the bucket; it is NOT CoachWardHead.jpg and the
--     lowercase coachward.jpg 404s). photo_url stores the full public URL, same
--     convention as the 062 rows.
--
-- Idempotent: the INSERT is guarded by NOT EXISTS, same as the Debose insert in 062.

BEGIN;

-- Justin Ward — new Receiver Coach.
INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Justin Ward', 'Receiver Coach', 'position_coach',
       'Justin_Ward@roundrockisd.org', 'Physical Education Teacher',
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWard.jpg',
       20, true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Justin Ward'
);

COMMIT;

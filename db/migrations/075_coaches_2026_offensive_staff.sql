-- 075_coaches_2026_offensive_staff.sql
--
-- Coaches page update (2026-27): five new football staff hires.
--   Coordinators (role_category='coordinator'):
--     * Alexander Gillis — Assistant Head Coach / Offensive Coordinator.
--       sort_order 4 (ahead of Hale's 5 — the senior coordinator).
--     * Barrett Matthews — Special Teams & Pass Game Coordinator. sort_order 6.
--   Position coaches (role_category='position_coach', after Ward's 20):
--     * Thomas Umberger — Wide Receivers Coach. sort_order 25.
--     * Ryan Doyle — Offensive Line Coach. sort_order 30.
--     * Devonte Jones — Defensive Backs Coach. sort_order 35.
--
-- Emails + teaching roles: only Doyle and Jones are in the RRISD staff directory
-- (verified 2026-07-21) — Doyle = Physical Education, Jones = Special Education,
-- teaching_role in the "{Dept} Teacher" style per the 062/066 convention. Gillis,
-- Matthews, and Umberger are not in the district directory yet, so their email +
-- teaching_role are left NULL (not fabricated) — fill when available.
--
-- No photos yet: the RRISD directory hosts no real headshots (logo placeholder
-- for everyone), so photo_url is NULL and the CoachCard renders its initials
-- fallback. Drop real photos into the coach-photos bucket + set photo_url later.
--
-- Idempotent: each INSERT is guarded by NOT EXISTS on (year, name), same as 062/066.

BEGIN;

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Alexander Gillis', 'Assistant Head Coach / Offensive Coordinator', 'coordinator',
       NULL, NULL, NULL, 4, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Alexander Gillis');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Barrett Matthews', 'Special Teams & Pass Game Coordinator', 'coordinator',
       NULL, NULL, NULL, 6, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Barrett Matthews');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Thomas Umberger', 'Wide Receivers Coach', 'position_coach',
       NULL, NULL, NULL, 25, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Thomas Umberger');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Ryan Doyle', 'Offensive Line Coach', 'position_coach',
       'Ryan_Doyle@roundrockisd.org', 'Physical Education Teacher', NULL, 30, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Ryan Doyle');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Devonte Jones', 'Defensive Backs Coach', 'position_coach',
       'devonte_jones@roundrockisd.org', 'Special Education Teacher', NULL, 35, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Devonte Jones');

COMMIT;

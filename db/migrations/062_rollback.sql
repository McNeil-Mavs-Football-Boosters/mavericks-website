-- 062_rollback.sql
-- Reverses 062_coaches_teaching_roles_and_debose.sql.

BEGIN;

-- Remove Debose.
DELETE FROM coaches
WHERE year = '2026-27' AND name = 'Reginal Debose';

-- Revert Gardner's email to its pre-062 state (was NULL).
UPDATE coaches
SET email = NULL
WHERE year = '2026-27' AND name = 'Jerry Gardner'
  AND email = 'jerry_gardner@roundrockisd.org';

-- Revert Wallin's email + photo to their pre-062 state (both were NULL).
UPDATE coaches
SET email = NULL,
    photo_url = NULL
WHERE year = '2026-27' AND name = 'Douglas Wallin'
  AND email = 'Douglas_Wallin@roundrockisd.org';

-- Revert Hale's photo to its pre-062 state (was NULL; email predates 062).
UPDATE coaches
SET photo_url = NULL
WHERE year = '2026-27' AND name = 'Michael Hale'
  AND photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachHaleHead.jpg';

-- Drop the teaching_role column (also clears Wallin/Hale values).
ALTER TABLE coaches DROP COLUMN IF EXISTS teaching_role;

COMMIT;

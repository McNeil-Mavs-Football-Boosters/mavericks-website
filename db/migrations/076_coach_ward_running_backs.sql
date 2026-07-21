-- 076_coach_ward_running_backs.sql
--
-- Justin Ward moves from Receiver Coach to Running Backs Coach (2026-27).
-- Resolves the two-receivers overlap created by migration 075 (Umberger came
-- on as Wide Receivers Coach); Ward now owns RBs, Umberger owns WRs.
-- "Running Backs" is two words (standard spelling). role_category, email,
-- teaching_role, photo, and sort_order all unchanged.
--
-- Idempotent: guarded on the old role value.

BEGIN;

UPDATE coaches
SET role = 'Running Backs Coach'
WHERE year = '2026-27'
  AND name = 'Justin Ward'
  AND role = 'Receiver Coach';

COMMIT;

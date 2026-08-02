-- 110_coach_photos_umberger_jones.sql
--
-- Head-shot photos for Thomas Umberger (WR) and Devonte Jones (DB), cropped from
-- their "Welcome to Mav Nation" announcement graphics and uploaded to the
-- coach-photos bucket. Same pattern as migration 093 did for Gillis, Matthews
-- and Edwards.
--
-- Why these two were skipped in 093: their graphics did not exist locally when
-- that batch ran on 2026-07-26 (the files landed that evening, several hours
-- after the session ended). They have been carried as an open item in
-- followups.md since. Jeremy supplied both on 2026-08-02.
--
-- Ryan Doyle (OL) STILL HAS NO PHOTO -- no graphic has ever been provided. He
-- keeps the horseshoe-mark fallback and stays on the followups list.
--
-- Idempotent: plain UPDATEs matched on name + year.

BEGIN;

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachUmbergerHead.jpg'
WHERE year = '2026-27' AND name = 'Thomas Umberger';

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachJonesHead.jpg'
WHERE year = '2026-27' AND name = 'Devonte Jones';

COMMIT;

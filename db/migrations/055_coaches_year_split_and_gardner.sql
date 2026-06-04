-- Migration 055: Decouple the coaches display year from current_year, advance it
-- to 2026-27, and seed Jerry Gardner as Head Coach and Athletic Director.
--
-- Why a new year field: current_year governs ALL football data (rosters,
-- players, practice_schedules, games, coaches). The new head coach was named
-- 2026-06-03 and Jeremy wants the /coaches page to show the 2026-27 staff NOW,
-- while rosters/schedule/games stay on the completed 2025-26 season. Mirrors the
-- existing current_board_year decoupling from migration 030.
--
-- Changes (single transaction):
--   1. Add site_settings.current_coaches_year (default '2026-27'); coaches page
--      will read this instead of current_year.
--   2. Re-stamp the two existing coaches (Hale, Wallin) 2025-26 -> 2026-27 so
--      they keep showing under the now-2026-27 coaches page.
--   3. Insert Jerry Gardner (role_category 'head') at 2026-27 with his photo.
--
-- Idempotent: column add is IF NOT EXISTS; the year re-stamp filters by old
-- value; the Gardner insert guards on NOT EXISTS. Reversible via 055_rollback.sql.

BEGIN;

ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_coaches_year text NOT NULL DEFAULT '2026-27';

UPDATE site_settings SET current_coaches_year = '2026-27' WHERE id = 1;

UPDATE coaches SET year = '2026-27' WHERE year = '2025-26';

INSERT INTO coaches (year, name, role, role_category, photo_url, bio, sort_order, active)
SELECT
  '2026-27',
  'Jerry Gardner',
  'Head Coach and Athletic Director',
  'head',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/JerryGardner.png',
  'Jerry Gardner joins McNeil as head football coach in 2026. He comes from Wylie East, where he served as offensive coordinator and quarterbacks coach and helped lead the program to consecutive 10-win seasons. He previously was head coach at Glenpool High School in Oklahoma and coached in Plano ISD. A native of Lone Grove, Oklahoma, Gardner played college football at the University of Central Oklahoma.',
  1,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND role_category = 'head'
);

COMMIT;

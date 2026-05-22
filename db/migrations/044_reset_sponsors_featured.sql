-- 044_reset_sponsors_featured.sql
-- Reset sponsors.featured to false for all 2025-26 rows. The featured flag
-- was originally used by the hero carousel sponsor_spotlight tiles to pick
-- which sponsors got airtime; those tiles were removed in migration 043.
-- The homepage strip now partitions by tier name (MVP vs non-MVP) instead of
-- the featured flag. The column stays in the schema for future use cases
-- (e.g. "featured sponsor of the month" or admin-driven badging).
--
-- Pre-check: grep across app/, lib/, components/ confirmed no live code path
-- reads sponsors.featured at the time this migration was written.

begin;

update sponsors
  set featured = false
  where year = '2025-26';

commit;

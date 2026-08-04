-- 111_rollback.sql
-- Reverses 111: puts Rudy's BBQ back on the site at MVP in both seasons.
--
-- This is also the "Rudy's actually signed" path -- if they come through as a
-- sponsor, run this (or just flip the 2026-27 row) rather than writing a new
-- insert; the row and the logo object were never deleted. Check the tier is
-- still right for whatever they actually pay before flipping.

begin;

update sponsors
set active = true
where name = 'Rudy''s BBQ'
  and year in ('2025-26', '2026-27');

commit;

-- 111_rudys_deactivate_not_a_sponsor.sql
--
-- Rudy's BBQ is NOT a sponsor. Jeremy confirmed 2026-08-03 after checking --
-- the logo has been on the site since the migration 041 placeholder seed, was
-- correctly removed by 060, then wrongly restored by 094 on a bad confirmation,
-- and carried into the 2026-27 lineup by 106. Ends here.
--
-- DEACTIVATE, DO NOT DELETE. Jeremy wants the row (and the logo object
-- sponsor-logos/rudys-bbq.png) held in case Rudy's does sponsor later --
-- flipping `active` back to true is then the whole job. Every public sponsor
-- query filters `.eq("active", true)` (app/page.tsx, app/sponsors/page.tsx,
-- app/boosters/sponsor/page.tsx), so active=false is equivalent to gone on the
-- site while the row survives.
--
-- Both season rows are deactivated, not just the live one. 2026-27 is what
-- current_year points at today; the 2025-26 row is only invisible because of
-- that pointer, and would resurface on any year flip back (or a 106 rollback).
-- Rudy's was never a sponsor in either season, so neither row should render.
--
-- CONSEQUENCE (same as when 060 did this): Rudy's is the only MVP-tier sponsor,
-- so after this the MVP slot is empty in 2026-27. Both surfaces guard on
-- sponsor-count > 0 per tier, so nothing breaks -- the /sponsors MVP section
-- stops rendering its h2 entirely and the homepage strip drops its top-tier
-- row, leaving the 5 remaining logos (2 Platinum, 1 Gold, 2 Blue) on row 2.
-- Side effect worth knowing: the "bigger sponsorship = bigger logo" hierarchy
-- now tops out at Platinum on the page prospects see.
--
-- Idempotent.

begin;

update sponsors
set active = false
where name = 'Rudy''s BBQ'
  and year in ('2025-26', '2026-27');

commit;

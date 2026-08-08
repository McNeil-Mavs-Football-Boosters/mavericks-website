-- 115_rollback.sql
--
-- Reverses 115. Restores Rudy's 2026-27 row to the state migration 111 left it
-- in (deactivated MVP sponsor), then drops the discriminator.
--
-- ⚠️ Dropping `kind` reclassifies EVERY community partner as a sponsor, so they
-- would start rendering on /sponsors and the homepage strip. If you only want to
-- unpublish one partner, do NOT run this — just deactivate that row:
--     update sponsors set active = false where id = '<id>';

begin;

update sponsors
set kind       = 'sponsor',
    active     = false,
    sort_order = 1,
    tier_id    = (
      select id from sponsorship_tiers
      where year = '2026-27' and name = 'MVP' and active
      limit 1
    )
where year = '2026-27'
  and name = 'Rudy''s BBQ';

alter table sponsors drop constraint if exists sponsors_kind_check;
alter table sponsors drop column if exists kind;

commit;

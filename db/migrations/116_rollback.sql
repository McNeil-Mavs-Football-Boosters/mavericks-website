-- 116_rollback.sql
--
-- Removes the seven partners added by 116 and restores Rudy's sort_order to 1.
-- Leaves the logo objects in the sponsor-logos bucket (harmless, and re-running
-- 116 then works without re-uploading).
--
-- To drop just ONE partner, don't run this — deactivate that row:
--   update sponsors set active = false where name = '<name>' and year = '2026-27';

begin;

delete from sponsors
where year = '2026-27'
  and kind = 'community_partner'
  and name in (
    'Amy''s Ice Creams',
    'Chicoine Chiropractic',
    'Jack Allen''s Kitchen',
    'Mighty Fine Burgers',
    'Phil''s Icehouse',
    'The League Kitchen & Tavern',
    'Tony C''s Coal Fired Pizza'
  );

update sponsors set sort_order = 1
where year = '2026-27' and kind = 'community_partner' and name = 'Rudy''s BBQ';

commit;

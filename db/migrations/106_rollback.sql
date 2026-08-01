-- 106_rollback.sql
-- Returns the sponsor surfaces to 2025-26 and removes the 2026-27 lineup.
-- The uploaded logo objects are left in the bucket (harmless if unreferenced).

begin;

update site_settings set current_year = '2025-26';

delete from sponsors where year = '2026-27';
delete from sponsorship_tiers where year = '2026-27';

commit;

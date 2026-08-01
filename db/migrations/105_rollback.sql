-- 105_rollback.sql
-- Removes the checklist row and restores the pre-105 SportsYou description
-- (captured from live before applying). Leaves the PDF in the documents bucket.

begin;

delete from resource_links
where label = '2026-27 Beginning of Year Checklist';

update resource_links
set description = 'Team messaging app for parents and players. Use the access code from the SportsYou invite page in the SE capture, or contact the booster club at boosters@mcneilmavericks.org.'
where section = 'communications'
  and label = 'SportsYou (Team Messaging)';

commit;

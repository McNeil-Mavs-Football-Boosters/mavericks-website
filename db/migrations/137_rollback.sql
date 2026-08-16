-- 137_rollback.sql — drops the coordinate columns (the ICS then omits GEO
-- everywhere, which is the pre-137 behaviour) and returns Chaparral Stadium to
-- migration 134's address search.

begin;

alter table venues drop column if exists latitude;
alter table venues drop column if exists longitude;

update venues
   set maps_url = 'https://maps.google.com/?q=4100+Westbank+Drive+Austin+TX+78746',
       updated_at = now()
 where name = 'Chaparral Stadium';

commit;

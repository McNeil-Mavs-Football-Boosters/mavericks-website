-- 206_rollback.sql -- returns the track venue to 205's unpinned, address-search state.
begin;
update venues
   set maps_url = 'https://maps.google.com/?q=Lake+Travis+High+School+Track+Stadium+3324+Ranch+Road+620+S+Austin+TX+78738',
       latitude = null, longitude = null, updated_at = now()
 where name = 'Lake Travis Track Stadium';
commit;

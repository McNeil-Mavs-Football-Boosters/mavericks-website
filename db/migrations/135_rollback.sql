-- 135_rollback.sql — puts the three pins back to migration 134's address links
-- and re-merges Maverick Stadium into the campus venue.

begin;

update games
   set venue_id = (select id from venues where name = 'McNeil High School')
 where location = 'Maverick Stadium';

update events
   set venue_id = (select id from venues where name = 'McNeil High School')
 where location = 'McNeil High School Stadium';

delete from venues where name = 'Maverick Stadium';

update venues set maps_url = 'https://maps.google.com/?q=10211+W+Parmer+Lane+Austin+TX+78717'
 where name = 'Kelly Reeves Athletic Complex';
update venues set maps_url = 'https://maps.google.com/?q=200+Gupton+Way+Drive+Cedar+Park+TX+78613'
 where name = 'Gupton Stadium';

commit;

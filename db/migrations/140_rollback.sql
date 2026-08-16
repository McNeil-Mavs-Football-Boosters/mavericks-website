-- 140_rollback.sql — back to the Rouse campus venue; drops Charles Rouse Stadium.

begin;

update games
   set venue_id = (select id from venues where name = 'Rouse High School')
 where location = 'Rouse HS';

delete from venues where name = 'Charles Rouse Stadium';

commit;

-- 142_rollback.sql — back to the Cedar Ridge campus venue; drops the stadium row.

begin;

update games
   set venue_id = (select id from venues where name = 'Cedar Ridge High School')
 where location = 'Cedar Ridge HS';

delete from venues where name = 'Cedar Ridge High School Football Stadium';

commit;

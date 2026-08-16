-- 141_rollback.sql — back to the Vista Ridge campus venue; drops the field row.

begin;

update games
   set venue_id = (select id from venues where name = 'Vista Ridge High School')
 where location = 'Vista Ridge HS';

delete from venues where name = 'Vista Ridge Football Field';

commit;

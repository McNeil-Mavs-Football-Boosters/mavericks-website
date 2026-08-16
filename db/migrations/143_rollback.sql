-- 143_rollback.sql — back to the Westwood campus venue; drops the Warrior Bowl row.

begin;

update games
   set venue_id = (select id from venues where name = 'Westwood High School')
 where location = 'Westwood HS';

delete from venues where name = 'Westwood Warrior Bowl';

commit;

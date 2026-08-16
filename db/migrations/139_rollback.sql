-- 139_rollback.sql — back to the Stony Point campus venue; drops Tiger Stadium.

begin;

update games
   set venue_id = (select id from venues where name = 'Stony Point High School')
 where location = 'Stony Point HS';

delete from venues where name = 'Stony Point Tiger Stadium';

commit;

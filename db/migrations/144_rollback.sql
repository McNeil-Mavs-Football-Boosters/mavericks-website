-- 144_rollback.sql — Westlake freshman rows back to the campus venue.

begin;

update games
   set venue_id = (select id from venues where name = 'Westlake High School')
 where location = 'Westlake HS';

commit;

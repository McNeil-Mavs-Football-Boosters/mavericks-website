-- 145_rollback.sql — Bowie freshman rows back to the Bowie campus venue. Run
-- this if Bowie's sub-varsity games turn out to be played on campus rather than
-- at Burger Stadium, then get a verified pin for the campus field.

begin;

update games
   set venue_id = (select id from venues where name = 'James Bowie High School')
 where location = 'Bowie HS';

commit;

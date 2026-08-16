-- 138_rollback.sql — points the Lake Travis game back at the campus venue and
-- removes Cavalier Stadium. Reintroduces the campus-vs-stadium gap (~480 m).

begin;

update games
   set venue_id = (select id from venues where name = 'Lake Travis High School')
 where location = 'Lake Travis HS';

delete from venues where name = 'Cavalier Stadium';

commit;

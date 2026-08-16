-- 144_westlake_freshman_at_chaparral.sql
--
-- Jeremy 2026-08-16: the Westlake games are at Chaparral, same as varsity's.
-- Both rows are freshman (Blue 5:00, Green 6:30, Thu Oct 15) and were pointing
-- at the 'Westlake High School' campus venue - the district address, ~260 m from
-- the stadium and never verified by anyone.
--
-- No new venue: Chaparral Stadium already carries Jeremy's verified pin and
-- coordinates from migration 137. This is a repoint, which is the whole reason
-- venues are rows rather than per-game URLs - the correction is one statement
-- and the pin it lands on is already trusted.
--
-- Answers a question 137 explicitly left open. That migration kept Chaparral and
-- 'Westlake High School' as separate venues precisely BECAUSE the freshman rows
-- said 'Westlake HS' and might have meant a side field; Jeremy has now said they
-- do not. The campus venue stays in the table, unreferenced, for a future row
-- that genuinely means the campus.

begin;

update games
   set venue_id = (select id from venues where name = 'Chaparral Stadium')
 where location = 'Westlake HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Chaparral Stadium';
  if n <> 3 then raise exception 'expected 3 games at Chaparral (1 varsity + 2 freshman), got %', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.location = 'Westlake HS' and v.latitude is null;
  if n <> 0 then raise exception '% Westlake games still lack a verified pin', n; end if;
end $$;

commit;

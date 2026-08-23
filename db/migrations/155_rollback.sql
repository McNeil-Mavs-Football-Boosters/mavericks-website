-- 155_rollback.sql
--
-- Restores the Aug 27-28 rows to what they held before migration 155: freshman
-- Green 6:30 p.m., freshman Blue 5:00 p.m., both labelled 'Burger Stadium' with the
-- Toney Burger Stadium pin, and varsity Aug 28 back to 7:00 p.m.
--
-- Unlike 153_rollback.sql this is a REAL rollback, not a no-op: Aug 27-28 are still
-- in the future, so the prior state is a schedule a parent could act on. Run it if
-- Coach's graphic turns out to be wrong.
--
-- The 'Toney Burger Annex' venue row is dropped only if nothing references it, so
-- running this while some other game still points at the annex leaves the row alone
-- rather than failing on the FK.

begin;

update games
   set location = 'Burger Stadium',
       venue_id = (select id from venues where name = 'Toney Burger Stadium')
 where year = '2026-27'
   and team_level = 'freshman'
   and location = 'Burger Annex'
   and game_date >= '2026-08-27 00:00:00 America/Chicago'
   and game_date <  '2026-08-28 00:00:00 America/Chicago';

update games
   set game_date = '2026-08-27 18:30:00 America/Chicago'
 where year = '2026-27'
   and team_level = 'freshman'
   and team_designation = 'Green'
   and game_date >= '2026-08-27 00:00:00 America/Chicago'
   and game_date <  '2026-08-28 00:00:00 America/Chicago';

update games
   set game_date = '2026-08-28 19:00:00 America/Chicago'
 where year = '2026-27'
   and team_level = 'varsity'
   and game_date >= '2026-08-28 00:00:00 America/Chicago'
   and game_date <  '2026-08-29 00:00:00 America/Chicago';

delete from venues v
 where v.name = 'Toney Burger Annex'
   and not exists (select 1 from games  g where g.venue_id = v.id)
   and not exists (select 1 from events e where e.venue_id = v.id);

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location = 'Burger Stadium'
     and v.name = 'Toney Burger Stadium';
  if n <> 3 then raise exception 'expected 3 Burger Stadium games after rollback, got %', n; end if;
end $$;

commit;

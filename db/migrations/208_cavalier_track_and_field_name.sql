-- 208_cavalier_track_and_field_name.sql
--
-- Jeremy 2026-09-22, after 207: "Cavelier Track and Field Stadium" -- i.e. name
-- the venue the way Google lists it rather than Coach's shorthand. Spelled
-- "Cavalier" to match the existing 'Cavalier Stadium' row and Google's listing;
-- the "Cavelier" in the message is a typo.
--
--   venues.name    'Lake Travis Track Stadium'  -> 'Cavalier Track and Field Stadium'
--   games.location (JV Sep 23)                  -> 'Cavalier Track and Field Stadium'
--   practice bodies: "at Lake Travis Track Stadium" -> "at Cavalier Track and Field Stadium (Lake Travis)"
--
-- The JV `notes` from 207 ("…not the Cavalier football stadium") stays: with two
-- venues now both starting "Cavalier", that line is the one thing that tells a
-- family which one. `venues.name` is unique, so the rename is guarded on the new
-- name not already existing.
--
-- DB-ONLY, NO DEPLOY. Rollback: 208_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from venues where name = 'Lake Travis Track Stadium';
  if n <> 1 then raise exception 'Lake Travis Track Stadium venue not found (already renamed?)'; end if;
  select count(*) into n from venues where name = 'Cavalier Track and Field Stadium';
  if n <> 0 then raise exception 'Cavalier Track and Field Stadium already exists'; end if;
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%at Lake Travis Track Stadium%';
  if n <> 3 then raise exception 'expected 3 bodies naming Lake Travis Track Stadium, found %', n; end if;
end $$;

update venues set name = 'Cavalier Track and Field Stadium', updated_at = now()
 where name = 'Lake Travis Track Stadium';

update games set location = 'Cavalier Track and Field Stadium', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and location = 'Lake Travis Track Stadium';

update practice_schedules
   set body = replace(body, 'at Lake Travis Track Stadium', 'at Cavalier Track and Field Stadium (Lake Travis)'),
       updated_at = now()
 where year = '2026-27' and body like '%at Lake Travis Track Stadium%';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv'
     and g.game_date = timestamptz '2026-09-23 18:00 America/Chicago'
     and g.location = 'Cavalier Track and Field Stadium' and v.name = 'Cavalier Track and Field Stadium'
     and v.latitude = 30.3233032;
  if n <> 1 then raise exception 'JV row / venue rename did not take'; end if;
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Lake Travis Track Stadium%';
  if n <> 0 then raise exception '% bodies still say Lake Travis Track Stadium', n; end if;
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%at Cavalier Track and Field Stadium (Lake Travis)%';
  if n <> 3 then raise exception 'rename missing from % bodies', 3 - n; end if;
end $$;

commit;

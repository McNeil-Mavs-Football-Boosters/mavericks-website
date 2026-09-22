-- 206_lake_travis_track_pin.sql
--
-- Fills in the map pin 205 deliberately left NULL on the Lake Travis Track
-- Stadium venue. Jeremy supplied the Google Maps place link for "Lake Travis
-- high school track and field" on 2026-09-22, minutes after 205 applied:
--
--   30.3235418, -97.9704399
--
-- That is about 270 m south-west of the Cavalier Stadium pin (30.3248488,
-- -97.9680765) -- same campus, different field, which is exactly why 205 made
-- a second venue row rather than reusing Cavalier (155's Burger Annex pattern).
-- Jeremy asked whether the club already had both Lake Travis fields: it did
-- not. Before 205 the venues were "Cavalier Stadium" (pinned) and a campus-level
-- "Lake Travis High School" (no pin); neither is the track.
--
-- The maps_url is Jeremy's link with the session tracking query (?entry=…&g_ep=…)
-- stripped; the place id and coordinates in the path are what make it resolve.
--
-- DB-ONLY, NO DEPLOY. Rollback: 206_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Travis Track Stadium' and latitude is null and longitude is null;
  if n <> 1 then raise exception 'Lake Travis Track Stadium not found unpinned (found %)', n; end if;
end $$;

update venues
   set maps_url = 'https://www.google.com/maps/place/Lake+Travis+high+school+track+and+field/@30.3233705,-97.9717634,545m/data=!3m1!1e3!4m6!3m5!1s0x865b393fa1e37c57:0x4b0946098420898f!8m2!3d30.3235418!4d-97.9704399!16s%2Fg%2F11h7k2hrt5',
       latitude = 30.3235418,
       longitude = -97.9704399,
       updated_at = now()
 where name = 'Lake Travis Track Stadium';

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Travis Track Stadium'
     and latitude = 30.3235418 and longitude = -97.9704399
     and maps_url like 'https://www.google.com/maps/place/Lake+Travis+high+school+track+and+field/%';
  if n <> 1 then raise exception 'pin did not take'; end if;
  -- Cavalier's pin is untouched.
  select count(*) into n from venues
   where name = 'Cavalier Stadium' and latitude = 30.3248488 and longitude = -97.9680765;
  if n <> 1 then raise exception 'Cavalier Stadium pin was disturbed'; end if;
end $$;

commit;

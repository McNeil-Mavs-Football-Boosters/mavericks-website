-- 207_lake_travis_track_official_listing.sql
--
-- Second pin correction for the Lake Travis Track Stadium venue, minutes after
-- 206. Jeremy sent a maps.app.goo.gl short link that resolves to Google's OWN
-- listing for the field:
--
--   "Cavalier Track and Field Stadium"   30.3233032, -97.9713134
--   place id 0x865b3831e8bc4edd:0x870821b56805c35b
--
-- 206 used a user-contributed place ("Lake Travis high school track and field",
-- 30.3235418, -97.9704399), ~90 m away. Same field, but the official listing is
-- what a parent gets when they search Maps for it, so the link points there.
--
-- ⚠️ THE VENUE NAME STAYS 'Lake Travis Track Stadium' -- Coach's exact words, and
-- what parents heard. Google's name goes in the maps link only. The game's
-- `notes` is reworded because "Track stadium, not Cavalier Stadium" next to a
-- map labelled "Cavalier Track and Field Stadium" reads as a contradiction:
-- it now says which Cavalier it is NOT (the football stadium).
--
-- Tracking query (?entry=tts&g_ep=…&skid=…) stripped from the stored URL.
--
-- DB-ONLY, NO DEPLOY. Rollback: 207_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Travis Track Stadium' and latitude = 30.3235418 and longitude = -97.9704399;
  if n <> 1 then raise exception 'track venue not found at the 206 pin (found %)', n; end if;
end $$;

update venues
   set maps_url = 'https://www.google.com/maps/place/Cavalier+Track+and+Field+Stadium/@30.3233705,-97.9717634,545m/data=!3m1!1e3!4m6!3m5!1s0x865b3831e8bc4edd:0x870821b56805c35b!8m2!3d30.3233032!4d-97.9713134!16s%2Fg%2F11fz97pr_6',
       latitude = 30.3233032,
       longitude = -97.9713134,
       updated_at = now()
 where name = 'Lake Travis Track Stadium';

update games
   set notes = 'Track and field stadium on the Lake Travis campus, not the Cavalier football stadium',
       updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and location = 'Lake Travis Track Stadium';

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Travis Track Stadium'
     and latitude = 30.3233032 and longitude = -97.9713134
     and maps_url like 'https://www.google.com/maps/place/Cavalier+Track+and+Field+Stadium/%'
     and maps_url not like '%entry=%';
  if n <> 1 then raise exception 'pin did not take'; end if;
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
     and notes = 'Track and field stadium on the Lake Travis campus, not the Cavalier football stadium';
  if n <> 1 then raise exception 'note did not take'; end if;
end $$;

commit;

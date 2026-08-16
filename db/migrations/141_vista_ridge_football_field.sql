-- 141_vista_ridge_football_field.sql
--
-- Vista Ridge: football field pin from Jeremy, 2026-08-16. Sixth split; pin
-- 30.5192122,-97.7873188 vs the campus at 30.5165045,-97.7878702, ~300 m apart.
--
-- ⚠️ THIS URL IS SHAPED DIFFERENTLY from the previous five and the difference
-- matters when reading coordinates out by hand. The earlier links carried a
-- STREET ADDRESS in the `!1m8!3m7…!2s<address>` segment; this one carries a
-- PLACE, `!2sVista+Ridge+High+School`, with its own coordinates. The rule is
-- unchanged and is about position, not content: the pin is always the LAST
-- `!3m5!…!8m2!3d<lat>!4d<lon>` group, the selected feature. The earlier group is
-- context Google threw in, whatever its type.
--
-- Because that segment is a place rather than an address, this URL supplies NO
-- street address, so the venue keeps Leander ISD's published one. That is fine:
-- `address` feeds the ICS LOCATION text and `latitude/longitude` feed GEO, and
-- only the latter needs to be exact.
--
-- Three rows move, including a 2025-26 JV game - same all-seasons treatment as
-- every venue since 135. The 2026-27 pair are freshman Blue and Green, so the
-- Rouse caveat applies: this is "the field at Vista Ridge", not proof the
-- freshmen play on it.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Vista Ridge Football Field',
   '200 S Vista Ridge Boulevard, Cedar Park, TX 78613',
   'https://www.google.com/maps/place/Vista+Ridge+Football+Field/@30.519268,-97.7895439,793m/data=!3m1!1e3!4m14!1m7!3m6!1s0x865b2d2c6700680b:0x36319648a550950d!2sVista+Ridge+High+School!8m2!3d30.5165045!4d-97.7878702!16zL20vMDl6NHR4!3m5!1s0x865b2dbedc7b71f5:0xa5c5b56470d0bb53!8m2!3d30.5192122!4d-97.7873188!16s%2Fg%2F11js4mz_yd',
   30.5192122, -97.7873188)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Vista Ridge Football Field')
 where location = 'Vista Ridge HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Vista Ridge Football Field';
  if n <> 3 then raise exception 'expected 3 games at Vista Ridge (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Vista Ridge HS' and venue_id is null;
  if n <> 0 then raise exception '% Vista Ridge games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

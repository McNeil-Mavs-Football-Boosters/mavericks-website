-- 142_cedar_ridge_stadium.sql
--
-- Cedar Ridge: football stadium pin from Jeremy, 2026-08-16. Seventh split; pin
-- 30.4926553,-97.6377619 vs the campus address pin in the same URL (2801 Gattis
-- School Rd) at 30.4948292,-97.6421454, ~450 m apart.
--
-- Four rows move, two per season, all FRESHMAN Blue + Green. Same caveat as
-- Rouse and Vista Ridge: this is the stadium at Cedar Ridge, not proof the
-- freshmen play in it. 'Cedar Ridge High School' (campus) stays unreferenced.
--
-- Note Cedar Ridge is an RRISD school, so its rows may move to a shared district
-- facility in a future season the way McNeil's own varsity home games sit at KRAC
-- rather than Maverick Stadium. If that happens the fix is repointing rows, not
-- editing this venue - the stadium itself has not moved.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Cedar Ridge High School Football Stadium',
   '2801 Gattis School Road, Round Rock, TX 78664',
   'https://www.google.com/maps/place/Cedar+Ridge+High+School+Football+Stadium/@30.4923251,-97.6385667,200m/data=!3m1!1e3!4m15!1m8!3m7!1s0x8644d025c69c508f:0xae9add38c6a1c93e!2s2801+Gattis+School+Rd,+Round+Rock,+TX+78664!3b1!8m2!3d30.4948292!4d-97.6421454!16s%2Fg%2F11p_836m1c!3m5!1s0x8644d1048f24f785:0x2ffd06061a5c04d1!8m2!3d30.4926553!4d-97.6377619!16s%2Fg%2F11t_m4j9mn',
   30.4926553, -97.6377619)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Cedar Ridge High School Football Stadium')
 where location = 'Cedar Ridge HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Cedar Ridge High School Football Stadium';
  if n <> 4 then raise exception 'expected 4 games at Cedar Ridge (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Cedar Ridge HS' and venue_id is null;
  if n <> 0 then raise exception '% Cedar Ridge games lost their venue', n; end if;

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

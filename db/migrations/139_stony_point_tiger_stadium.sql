-- 139_stony_point_tiger_stadium.sql
--
-- Stony Point: Tiger Stadium pin from Jeremy, 2026-08-16. Fourth stadium/campus
-- split; the pin is 30.5304036,-97.6642866 and the campus address pin inside the
-- same URL (1801 Tiger Trail) is 30.5291345,-97.6609148, ~350 m apart.
--
-- Running tally of pin-vs-campus distance, which is why this is now the default
-- assumption rather than a surprise:
--   Maverick Stadium   ~200 m (135)
--   Chaparral          ~260 m (137)
--   Cavalier           ~480 m (138)
--   Tiger Stadium      ~350 m (this one)
--
-- Both seasons' rows move (2025-26 JV and 2026-27 JV) - same treatment the
-- 'Maverick Stadium' rows got in 135. The archived row is not worth a second
-- venue and the place has not moved.
--
-- 'Stony Point High School' (campus, district address, no coordinates) stays in
-- the table unreferenced, for the same reason 138 kept the Lake Travis campus
-- row: away fields vary and a future row may mean the campus.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Stony Point Tiger Stadium',
   '1801 Tiger Trail, Round Rock, TX 78664',
   'https://www.google.com/maps/place/Stony+Point+Tiger+Stadium/@30.5304751,-97.6642963,429m/data=!3m1!1e3!4m15!1m8!3m7!1s0x8644d1a95ddb5b4d:0xdf7c6cd9c4b0eae7!2s1801+Tiger+Trail,+Round+Rock,+TX+78664!3b1!8m2!3d30.5291345!4d-97.6609148!16s%2Fg%2F11bw3zlw8g!3m5!1s0x8644d13a7999f74d:0x1264a8be29585b53!8m2!3d30.5304036!4d-97.6642866!16s%2Fg%2F11tk47mzh9',
   30.5304036, -97.6642866)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Stony Point Tiger Stadium')
 where location = 'Stony Point HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Stony Point Tiger Stadium';
  if n <> 2 then raise exception 'expected 2 games at Tiger Stadium (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Stony Point HS' and venue_id is null;
  if n <> 0 then raise exception '% Stony Point games lost their venue', n; end if;

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

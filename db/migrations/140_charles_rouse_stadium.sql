-- 140_charles_rouse_stadium.sql
--
-- Rouse: Charles Rouse Stadium pin from Jeremy, 2026-08-16. Fifth stadium/campus
-- split; pin 30.5690341,-97.8194206 vs the campus address pin in the same URL
-- (1222 Raider Way) at 30.5719732,-97.8205576, ~340 m apart.
--
-- Both rows here are FRESHMAN games (Blue 5:00, Green 6:30, Thu Sep 10) - the
-- first time a verified stadium pin lands on freshman rows rather than varsity
-- or JV. Jeremy has been explicit that freshman and JV away fields vary, so this
-- is "the stadium at Rouse" and not proof the freshmen play in it. It is still
-- strictly better than the campus address, which is 340 m from the stadium and
-- was never verified either. Repoint if better specifics arrive.
--
-- 'Rouse High School' (campus, district address, no coordinates) stays in the
-- table unreferenced, same as the Lake Travis and Stony Point campus rows.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Charles Rouse Stadium',
   '1222 Raider Way, Leander, TX 78641',
   'https://www.google.com/maps/place/Charles+Rouse+Stadium/@30.5690449,-97.8202182,194m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b2b7c557294af:0x850a0cddfe02943e!2s1222+Raider+Way,+Leander,+TX+78641!3b1!8m2!3d30.5719732!4d-97.8205576!16s%2Fg%2F11rp1yvtfm!3m5!1s0x865b2b939c10e7b7:0x496208446df75b27!8m2!3d30.5690341!4d-97.8194206!16s%2Fg%2F11gnsckwc7',
   30.5690341, -97.8194206)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Charles Rouse Stadium')
 where location = 'Rouse HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Charles Rouse Stadium';
  if n <> 2 then raise exception 'expected 2 games at Charles Rouse Stadium, got %', n; end if;

  select count(*) into n from games where location = 'Rouse HS' and venue_id is null;
  if n <> 0 then raise exception '% Rouse games lost their venue', n; end if;

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

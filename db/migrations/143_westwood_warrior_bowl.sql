-- 143_westwood_warrior_bowl.sql
--
-- Westwood: Warrior Bowl pin from Jeremy, 2026-08-16. Eighth split; pin
-- 30.4585172,-97.7979725 vs the campus address pin in the same URL (12400 Mellow
-- Meadow Dr) at 30.4566119,-97.7980504, ~210 m apart - the tightest of the eight,
-- and still a different parking lot.
--
-- Three rows move (2026-27 freshman Blue + Green, one 2025-26 row). Freshman
-- caveat applies as with Rouse, Vista Ridge and Cedar Ridge. 'Westwood High
-- School' (campus) stays unreferenced.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Westwood Warrior Bowl',
   '12400 Mellow Meadow Drive, Austin, TX 78750',
   'https://www.google.com/maps/place/Westwood+Warrior+Bowl/@30.4572381,-97.800711,794m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b32b867e9bfb5:0xd13fe8ad8cfb759e!2s12400+Mellow+Meadow+Dr,+Austin,+TX+78750!3b1!8m2!3d30.4566119!4d-97.7980504!16s%2Fg%2F11c3q4cb8c!3m5!1s0x865b33612b05c789:0x8420ac02db4a7637!8m2!3d30.4585172!4d-97.7979725!16s%2Fg%2F11j2x_qn_f',
   30.4585172, -97.7979725)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Westwood Warrior Bowl')
 where location = 'Westwood HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Westwood Warrior Bowl';
  if n <> 3 then raise exception 'expected 3 games at Warrior Bowl (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Westwood HS' and venue_id is null;
  if n <> 0 then raise exception '% Westwood games lost their venue', n; end if;

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

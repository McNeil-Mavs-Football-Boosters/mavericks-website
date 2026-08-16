-- 138_cavalier_stadium.sql
--
-- Lake Travis: Cavalier Stadium pin from Jeremy, 2026-08-16.
--
-- Third stadium/campus split in a row, and the pattern is now established beyond
-- doubt: the pin he sent is 30.3248488,-97.9680765 while the campus address pin
-- inside the SAME URL (3324 Ranch Rd 620 S) is 30.3282475,-97.9666167 - about
-- 480 m apart. Maverick Stadium was ~200 m from its campus pin (135) and
-- Chaparral ~260 m (137). Assume they differ until shown otherwise.
--
-- So Cavalier Stadium is its own venue and the one game that plays there is
-- repointed. 'Lake Travis High School' (the campus, with the district address
-- and no coordinates) stays in the table but is now referenced by nothing - kept
-- deliberately, because the JV/freshman away fields vary and a future row may
-- genuinely mean the campus rather than the varsity stadium. An unused venue row
-- costs nothing; re-deriving a deleted one costs a lookup.
--
-- ⚠️ Only ONE game currently plays here (JV, Wed Sep 23) - varsity hosts Lake
-- Travis at KRAC and the freshmen host at Maverick Stadium. That single row is
-- an AWAY JV game, and Jeremy has flagged that JV and freshman away fields vary,
-- so this pin is "the stadium at Lake Travis", not proof that JV plays in it. If
-- it turns out they play a side field, add that venue and repoint this one row.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Cavalier Stadium',
   '3324 Ranch Road 620 S, Austin, TX 78738',
   'https://www.google.com/maps/place/Cavalier+Stadium/@30.3240184,-97.9696299,588m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b382c58a80363:0x336b14128be316f7!2s3324+Ranch+Rd+620+S,+Austin,+TX+78738!3b1!8m2!3d30.3282475!4d-97.9666167!16s%2Fg%2F11c0px86wt!3m5!1s0x865b3831d8480283:0xf7d2f43ae250066f!8m2!3d30.3248488!4d-97.9680765!16s%2Fg%2F1wg5yf21',
   30.3248488, -97.9680765)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Cavalier Stadium')
 where location = 'Lake Travis HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Cavalier Stadium';
  if n <> 1 then raise exception 'expected 1 game at Cavalier Stadium, got %', n; end if;

  select count(*) into n from games where location = 'Lake Travis HS' and venue_id is null;
  if n <> 0 then raise exception '% Lake Travis games lost their venue', n; end if;

  -- Carry forward every rule from 136 + 137 on the whole table, so a later
  -- migration cannot quietly break them.
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

-- /schedule/games/* and /events read at request time: live with no deploy.

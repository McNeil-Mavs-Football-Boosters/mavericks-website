-- 137_venue_coordinates.sql
--
-- Coordinates on venues, so the ICS feed can emit a GEO property (RFC 5545
-- § 3.8.1.6) alongside LOCATION. Plus Chaparral Stadium's real pin from Jeremy.
--
-- ── WHY ──
-- The calendar is the weakest surface for precision and the one people rely on
-- when they are already driving. A subscribed VEVENT can only carry LOCATION,
-- a text string that the phone geocodes itself - which is exactly how Lake
-- Belton sent people to a road centerline 920 m from the school (migration 136).
-- GEO carries the point itself, so clients that support it stop guessing.
--
-- ⚠️ GEO IS NEVER GUESSED. Coordinates are set ONLY for venues where a human
-- opened the pin: the five place links Jeremy sent (Maverick Stadium, KRAC,
-- Gupton, Dragon Stadium, Burger), the Lake Belton dropped pin, and Chaparral
-- below. Every other venue keeps latitude/longitude NULL and the feed omits GEO
-- for it, leaving today's behaviour (the client geocodes the address) untouched.
--
-- Geocoding the remaining addresses to fill the columns would have been easy and
-- WRONG: it would stamp unverified coordinates into subscribers' calendars with
-- the authority of a precise point, which is a worse failure than the vague
-- address it replaced. The whole reason this column exists is that Jeremy found
-- two street addresses in a row that pointed at the wrong place. NULL is the
-- honest value until someone opens the pin.
--
-- Coordinates are lifted from the `!3m5!…!8m2!3d<lat>!4d<lon>` segment of each
-- stored Maps URL - the SELECTED place, not the `!1m8!3m7…` segment earlier in
-- the same URL, which is the associated street address and is a different point.
-- On the Chaparral URL those two differ by ~260 m.
--
-- ── CHAPARRAL SPLITS FROM THE WESTLAKE CAMPUS ──
-- Same shape as Maverick Stadium in migration 135. 134 gave 'Chaparral Stadium'
-- and 'Westlake High School' the same 4100 Westbank Dr address search, because
-- the stadium is on the campus. Jeremy's link shows the stadium pin is
-- 30.2776477,-97.813297 and the campus address pin is 30.2752887,-97.8130021.
-- Varsity plays at Chaparral; the JV and freshman rows say 'Westlake HS' and may
-- well be a different field on the same campus, which is exactly the away-field
-- variance Jeremy flagged - so the two venues stay separate rows and only
-- Chaparral gets the verified pin.

begin;

alter table venues add column if not exists latitude  double precision;
alter table venues add column if not exists longitude double precision;

comment on column venues.latitude is
  'Decimal degrees, NULL unless a human has opened the pin. Emitted as the ICS '
  'GEO property. Never fill this by geocoding an address - an unverified point '
  'presented as exact is worse than no point at all.';

update venues set
  maps_url = 'https://www.google.com/maps/place/Chaparral+Stadium%2FEbbie+Neptune+Field/@30.277489,-97.8138113,692m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b4a8e09cd721f:0xc89a7e416cdbb18e!2s4100+Westbank+Dr,+Austin,+TX+78746!3b1!8m2!3d30.2752887!4d-97.8130021!16s%2Fg%2F11bw3gczyw!3m5!1s0x865b4a915eba75c3:0x6d7187a81942de97!8m2!3d30.2776477!4d-97.813297!16s%2Fm%2F0pyw91j',
  updated_at = now()
 where name = 'Chaparral Stadium';

update venues set latitude = 30.4503017, longitude = -97.7302712, updated_at = now()
 where name = 'Maverick Stadium';
update venues set latitude = 30.4926179, longitude = -97.7751922, updated_at = now()
 where name = 'Kelly Reeves Athletic Complex';
update venues set latitude = 30.5151663, longitude = -97.7919660, updated_at = now()
 where name = 'Gupton Stadium';
update venues set latitude = 30.5071207, longitude = -97.6953804, updated_at = now()
 where name = 'Round Rock High School Dragon Stadium';
update venues set latitude = 30.2305155, longitude = -97.8097468, updated_at = now()
 where name = 'Toney Burger Stadium';
update venues set latitude = 31.1437410, longitude = -97.4416740, updated_at = now()
 where name = 'Lake Belton High School';
update venues set latitude = 30.2776477, longitude = -97.8132970, updated_at = now()
 where name = 'Chaparral Stadium';

do $$
declare n int;
begin
  select count(*) into n from venues where latitude is not null;
  if n <> 7 then raise exception 'expected 7 venues with coordinates, got %', n; end if;

  -- Lat and lon are set together or not at all; half a coordinate is a bug.
  select count(*) into n from venues
   where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  -- Central Texas sanity box. Catches a swapped lat/lon or a dropped minus sign,
  -- which is the realistic way a coordinate goes wrong by hand.
  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;

  -- Every venue carrying coordinates must also carry the pin they came from.
  select count(*) into n from venues
   where latitude is not null
     and maps_url not like 'https://www.google.com/maps/%';
  if n <> 0 then raise exception '% venues have coordinates but no place pin', n; end if;
end $$;

commit;

-- Verification:
--   select name, latitude, longitude from venues where latitude is not null order by name;

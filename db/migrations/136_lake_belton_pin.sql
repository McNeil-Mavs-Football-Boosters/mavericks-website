-- 136_lake_belton_pin.sql
--
-- Lake Belton High School: exact pin from Jeremy, 2026-08-16, replacing 134's
-- address-search link, which he reported landed "in the middle of a road".
-- It did. Checked independently before writing this:
--   134's link      '9809 Prairie View Road, Temple, TX 76502'
--                   -> geocodes to a ROAD CENTERLINE with no house number,
--                      920 m from the school
--   Jeremy's pin    31.143741, -97.441674
--                   -> reverse-geocodes to house number 9809 on FM 2483
--
-- ⚠️ THE ADDRESS STRING CHANGES TOO, and that is the substantive half of this
-- migration. Belton ISD publishes the campus as both "9809 Prairie View Road"
-- and "9809 FM 2483"; only the FM 2483 form geocodes to the building. The
-- address is not decoration - the ICS feed emits it as LOCATION, and a phone
-- geocoding "Prairie View Road" would send a subscriber to the same wrong stretch
-- of road the old link did. Fixing the maps_url without fixing the address would
-- have left the calendar broken and looked done.
--
-- ── ON SHORT LINKS ──
-- Jeremy sent https://maps.app.goo.gl/L5biefyVV5WVPsPF9. It is EXPANDED here
-- rather than stored. A shortener is opaque - nobody reviewing this file, or
-- diffing it in a year, can tell where it points - and it adds a second service
-- that has to stay up for a link on the site to work (Google turned down the
-- general goo.gl shortener in 2025; maps.app.goo.gl survives, but there is no
-- reason to depend on it). Same reasoning as the Venmo QR sign in the
-- BoosterClub project: never ship an opaque pointer you cannot read back.
-- Resolved with `curl -I` and stored in the documented Maps URLs API form.
--
-- Note this pin is a COORDINATE SEARCH, not a named place like the Maverick
-- Stadium / KRAC / Gupton pins in migration 135. That is fine and arguably more
-- precise - it is an exact point rather than Google's centroid for a named
-- feature - but it means the map opens without a place card.

begin;

update venues
   set maps_url = 'https://www.google.com/maps/search/?api=1&query=31.143741%2C-97.441674',
       address  = '9809 FM 2483, Temple, TX 76502',
       updated_at = now()
 where name = 'Lake Belton High School';

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Belton High School'
     and address = '9809 FM 2483, Temple, TX 76502'
     and maps_url like '%31.143741%2C-97.441674';
  if n <> 1 then raise exception 'Lake Belton venue not updated as expected'; end if;

  -- No stored venue URL may be a shortener: opaque, and a second dependency.
  select count(*) into n from venues where maps_url like '%goo.gl%';
  if n <> 0 then raise exception '% venue URLs are shortened links', n; end if;

  -- Still no pasted Maps session junk (carried forward from 135).
  select count(*) into n from venues where maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs carry Maps session parameters', n; end if;
end $$;

commit;

-- /schedule/games/* and /events read at request time: live with no deploy.

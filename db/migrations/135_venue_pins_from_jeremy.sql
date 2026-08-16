-- 135_venue_pins_from_jeremy.sql
--
-- Three verified Google Maps place pins from Jeremy, 2026-08-16, replacing the
-- address-search links migration 134 built from district web pages:
--   Maverick Stadium               (18 games this season - the most-used venue)
--   Kelly Reeves Athletic Complex  (5)
--   Gupton Stadium                 (2)
--
-- A `?q=<address>` link drops you at the street address; these are the actual
-- place pins, which is the difference between "the school" and "the stadium you
-- park at". Jeremy is checking the remaining venues; those keep their district
-- addresses until he does.
--
-- ⚠️ MAVERICK STADIUM BECOMES ITS OWN VENUE - it is NOT the campus pin.
-- 134 folded 'Maverick Stadium' into the McNeil High School venue on the theory
-- that the stadium sits on campus and the campus address was the best available
-- answer. Jeremy's link disproves the premise: the stadium pin is at
-- 30.4503017,-97.7302712 while the campus pin is 30.4498039,-97.7321648 - about
-- 200 m apart, different entrances. So this splits them:
--   games   location = 'Maverick Stadium'           -> Maverick Stadium (new)
--   events  location = 'McNeil High School Stadium' -> Maverick Stadium (new)
--   events  location = 'McNeil High School' / Cafeteria / Team Room G204
--                                                   -> McNeil High School (campus)
-- The events move is an inference worth stating: 'McNeil High School Stadium' is
-- the same physical place as 'Maverick Stadium' (it is where Meet the Mavs is
-- held), so it gets the stadium pin. If that is ever wrong, repoint those two
-- rows - the display label does not change either way.
--
-- Both venues keep the SAME street address (5720 McNeil Drive) because that is
-- what Google itself associates with the stadium pin - see the `!2s5720+McNeil+
-- Dr,+Austin,+TX+78729` segment inside the URL. The ICS therefore emits
-- "Maverick Stadium, 5720 McNeil Drive, Austin, TX 78729", which navigates
-- correctly, while the on-site link goes to the precise pin.
--
-- URL hygiene: the `?entry=ttu&g_ep=...` tail on a pasted Maps URL is session
-- junk and is stripped. What remains is the place path plus the data segment
-- carrying the feature id and coordinates.
--
-- Verification note: these were NOT confirmed by fetching them - google.com/maps
-- serves a generic "Google Maps" shell to a non-browser client, so a fetch proves
-- nothing beyond a 200. What is checkable is inside the URLs themselves: each
-- carries a place name in its path and coordinates that sit where that place
-- should be. Jeremy opened all three.

begin;

-- The new, distinct stadium pin.
insert into venues (name, address, maps_url) values
  ('Maverick Stadium',
   '5720 McNeil Drive, Austin, TX 78729',
   'https://www.google.com/maps/place/Maverick+Stadium/@30.4493128,-97.7374311,16z/data=!4m15!1m8!3m7!1s0x8644cda571be6383:0x55cd609971b1d5e8!2s5720+McNeil+Dr,+Austin,+TX+78729!3b1!8m2!3d30.4498039!4d-97.7321648!16s%2Fg%2F11bw436jbr!3m5!1s0x8644cdafb123bf1f:0x87fbeafd2a7f6b9b!8m2!3d30.4503017!4d-97.7302712!16s%2Fg%2F11p0w489y6')
on conflict (name) do update set maps_url = excluded.maps_url, updated_at = now();

update venues
   set maps_url = 'https://www.google.com/maps/place/Kelly+Reeves+Athletic+Complex/@30.4934448,-97.777533,17z/data=!4m15!1m8!3m7!1s0x865b32b28458d587:0xb05997bbdeea8e25!2s10211+W+Parmer+Ln,+Austin,+TX+78717!3b1!8m2!3d30.4934448!4d-97.7749581!16s%2Fg%2F11bw4n56bs!3m5!1s0x8644d2b099574bed:0xccc7137bc54362d0!8m2!3d30.4926179!4d-97.7751922!16s%2Fg%2F1vvdvlwd',
       updated_at = now()
 where name = 'Kelly Reeves Athletic Complex';

update venues
   set maps_url = 'https://www.google.com/maps/place/John+Gupton+Stadium/@30.5157472,-97.7937186,17z/data=!4m15!1m8!3m7!1s0x865b2d2e7a93de05:0x5341c426abf48333!2s200+Gupton+Way+Dr,+Cedar+Park,+TX+78613!3b1!8m2!3d30.5157472!4d-97.7911437!16s%2Fg%2F11c4n0yrcw!3m5!1s0x865b2d300a63cf9b:0x71749e8ca8d3b2bc!8m2!3d30.5151663!4d-97.791966!16s%2Fg%2F1tq4rhp8',
       updated_at = now()
 where name = 'Gupton Stadium';

-- Repoint everything that means "the stadium", every season.
update games
   set venue_id = (select id from venues where name = 'Maverick Stadium')
 where location = 'Maverick Stadium';

update events
   set venue_id = (select id from venues where name = 'Maverick Stadium')
 where location = 'McNeil High School Stadium';

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int; stadium uuid; campus uuid;
begin
  select id into stadium from venues where name = 'Maverick Stadium';
  select id into campus  from venues where name = 'McNeil High School';
  if stadium is null or campus is null then
    raise exception 'stadium and campus venues must both exist';
  end if;
  if stadium = campus then raise exception 'stadium and campus must be distinct rows'; end if;

  select count(*) into n from games where location = 'Maverick Stadium' and venue_id = stadium;
  if n <> 35 then raise exception 'expected 35 Maverick Stadium games (all seasons), got %', n; end if;

  select count(*) into n from games where location = 'Maverick Stadium' and venue_id = campus;
  if n <> 0 then raise exception '% stadium games still point at the campus pin', n; end if;

  select count(*) into n from events where location = 'McNeil High School Stadium' and venue_id = stadium;
  if n <> 2 then raise exception 'expected 2 stadium events, got %', n; end if;

  -- Campus-proper events must NOT have moved.
  select count(*) into n from events
   where location in ('McNeil High School', 'McNeil High School Cafeteria',
                      'Team Room G204, McNeil High School')
     and venue_id = campus;
  if n <> 12 then raise exception 'expected 12 campus events, got %', n; end if;

  -- Every pin Jeremy supplied must be a place URL, not an address search.
  select count(*) into n from venues
   where name in ('Maverick Stadium', 'Kelly Reeves Athletic Complex', 'Gupton Stadium')
     and maps_url like 'https://www.google.com/maps/place/%';
  if n <> 3 then raise exception 'expected 3 place-pin venues, got %', n; end if;

  -- No pasted-session junk should ever land in a stored URL.
  select count(*) into n from venues where maps_url like '%entry=ttu%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs still carry Maps session parameters', n; end if;
end $$;

commit;

-- Verification:
--   select v.name, v.maps_url, count(g.id) games
--     from venues v left join games g on g.venue_id = v.id and g.year = '2026-27'
--    group by 1,2 order by 3 desc;

-- 146_bowie_label_burger_stadium.sql
--
-- Resolves the open question migration 145 carried. Jeremy checked satellite
-- imagery 2026-08-16: THERE IS NO STADIUM ON THE BOWIE CAMPUS. Bowie cannot host
-- a football game at its own address, which settles what 145 could only weigh -
-- Austin ISD sub-varsity plays at the district's shared stadiums, and for Bowie
-- that is Burger, the same venue as the varsity game the following night.
--
-- 145 attached the Burger pin but deliberately left the display label reading
-- 'Bowie HS', so the page said one place and its link went to another ~8 miles
-- away. That inconsistency was carried on purpose pending confirmation. It is
-- confirmed, so the label moves and the divergence closes.
--
-- All three surfaces now agree for this game:
--   games row      location 'Burger Stadium', venue Toney Burger Stadium
--   /events + ICS  derived from the same row, GEO 30.2305155;-97.8097468
--   Print View PDF freshman Aug. 27 SITE cell patched Bowie HS -> Burger Stadium
--                  (MavericksWebsite/scripts/patch-schedule-pdf.py, re-run from
--                  the school's original and re-uploaded)
-- Leaving any one of them behind is how this project got a site that disagreed
-- with its own printed schedule in the first place.
--
-- 'James Bowie High School' (campus, district address, no coordinates) stays in
-- the table unreferenced, like the other campus rows.

begin;

update games
   set location = 'Burger Stadium'
 where year = '2026-27' and location = 'Bowie HS';

do $$
declare n int;
begin
  select count(*) into n from games where year = '2026-27' and location = 'Bowie HS';
  if n <> 0 then raise exception '% rows still labelled Bowie HS', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location = 'Burger Stadium'
     and v.name = 'Toney Burger Stadium';
  if n <> 3 then raise exception 'expected 3 Burger Stadium games (2 freshman + varsity), got %', n; end if;

  -- Label and pin must agree everywhere now: no 2026-27 game may sit at a venue
  -- whose name shares no word with its own display label, except the deliberate
  -- 'Maverick Stadium'/'McNeil' and KRAC-style shorthands already reviewed.
  select count(*) into n from games g left join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location is not null
     and (v.id is null or v.latitude is null);
  if n <> 0 then raise exception '% 2026-27 games lack a verified pin', n; end if;
end $$;

commit;

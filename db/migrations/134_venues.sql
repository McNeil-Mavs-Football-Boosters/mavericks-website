-- 134_venues.sql
--
-- A `venues` table, and `venue_id` on games + events. Jeremy 2026-08-16, after
-- noticing that "Burger Stadium" on the schedule is not a link.
--
-- ── WHY A TABLE AND NOT JUST FILLING IN location_url ──
-- Both tables have had a `location_url` column since the beginning; it is NULL on
-- all 48 game rows and always has been, which is the entire reason the schedule
-- has no map links (the games table and game cards already render one the moment
-- the value exists). Filling in 48 URLs would have worked today and rotted
-- tomorrow: 18 rows say 'Maverick Stadium' and 5 say 'KRAC', so a corrected pin
-- would be 18 edits, and every new game row would need someone to remember to
-- paste a URL. One row per place, referenced by id, is the fix.
--
-- It also unlocks the thing a URL alone cannot do: the ICS feed can now emit
-- "Burger Stadium, 3200 Jones Road, Austin, TX" as the LOCATION, so a subscribed
-- phone can navigate to a Thursday away game. That needs a street address, which
-- there was nowhere to put.
--
-- ── ONE SOURCE, NOT TWO ──
-- `events.location_url` is CLEARED wherever a venue is attached, and the column
-- is left in place but deprecated (see the comment set below). A row that can
-- carry a link in two columns is the same drift trap as Meet the Mavs' time
-- living in an events row and in the practice markdown. One place.
--
-- ── ADDRESS SOURCING - every pin is from the school district or from Jeremy ──
--   McNeil                     already used site-wide (migration 108)
--   Kelly Reeves (KRAC)        Round Rock ISD facility page
--   Dragon Stadium             Jeremy 2026-08-16, with a Google Maps place link
--   Toney Burger Stadium       Austin ISD athletics page (3200, NOT the 3600 that
--                              several listing sites carry); link from Jeremy
--   Gupton Stadium             Leander ISD stadiums page
--   Chaparral Stadium          Westlake athletics facilities page
--   Opponent campuses          each district's own campus page
-- Nothing here is a guess. A wrong pin sends a family to the wrong stadium, which
-- is the failure this project spent 2026-08-16 fixing in the Print View PDF.
--
-- ── SCOPE: 2026-27 AND EVENTS ONLY ──
-- Last season's rows (2025-26) are matched only where the venue already exists in
-- this seed. Eight 2025-26 venues are deliberately NOT seeded - House Park, Hutto
-- HS, Manor HS, Memorial Stadium, Monroe Stadium, The Pfield, Vandegrift HS,
-- Weiss HS - because nobody navigates to last season's away games and inventing
-- pins for them is unpaid risk. Those rows keep venue_id NULL and render exactly
-- as they do today. The assertion below is scoped to 2026-27 accordingly.
--
-- ⚠️ ALIASES ARE A REAL HAZARD. The same place is already spelled two ways across
-- seasons: 'Gupton' (2026-27) vs 'Gupton Stadium' (2025-26), 'Dragon Stadium' vs
-- 'Round Rock HS', 'Chaparral' vs 'Chaparral Stadium'. This migration maps the
-- known aliases, but going forward the answer is to SET venue_id, not to type the
-- location string and hope it matches. `location` stays as the display label
-- (which is why 'Maverick Stadium' still reads "Maverick Stadium" and not "McNeil
-- High School") - the venue supplies the link and the address, nothing else.

begin;

create table if not exists venues (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  address    text not null,
  maps_url   text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table venues is
  'Physical places games and events happen. One row per place; games.venue_id / '
  'events.venue_id reference it. `address` is what the ICS feed emits so a phone '
  'can navigate; `maps_url` is what the site links to.';

alter table games  add column if not exists venue_id uuid references venues(id);
alter table events add column if not exists venue_id uuid references venues(id);

comment on column games.venue_id is
  'The place this game is played. Set this rather than typing a location string '
  'and hoping it matches a venue name - `location` is only the display label.';
comment on column events.location_url is
  'DEPRECATED (migration 134). Use venue_id; the venue owns the link. Kept only '
  'so no historical row loses data. Do not set on new rows.';

grant select on venues to anon, authenticated;
grant insert, update, delete on venues to authenticated;

alter table venues enable row level security;

create policy "Anyone reads venues" on venues
  for select to anon using (true);
create policy "Authenticated read venues" on venues
  for select to authenticated using (true);
create policy "Content admins write venues" on venues
  for insert to authenticated with check (current_user_has_role('content_admin'));
create policy "Content admins update venues" on venues
  for update to authenticated using (current_user_has_role('content_admin'))
  with check (current_user_has_role('content_admin'));
create policy "Content admins delete venues" on venues
  for delete to authenticated using (current_user_has_role('content_admin'));

-- ── the places ──────────────────────────────────────────────────────────────
insert into venues (name, address, maps_url) values
  ('McNeil High School',
   '5720 McNeil Drive, Austin, TX 78729',
   'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729'),
  ('Kelly Reeves Athletic Complex',
   '10211 W Parmer Lane, Austin, TX 78717',
   'https://maps.google.com/?q=10211+W+Parmer+Lane+Austin+TX+78717'),
  ('Round Rock High School Dragon Stadium',
   '201 Deep Wood Drive, Round Rock, TX 78681',
   'https://www.google.com/maps/place/Round+Rock+High+School+Dragon+Stadium/@30.5071484,-97.6961314,17z/data=!3m1!4b1!4m6!3m5!1s0x8644d1f4d7afa049:0x2acf18eb0c86d57c!8m2!3d30.5071207!4d-97.6953804!16s%2Fg%2F1thw_vbd'),
  ('Toney Burger Stadium',
   '3200 Jones Road, Austin, TX',
   'https://www.google.com/maps/place/Burger+Stadium/@30.2305155,-97.8123217,16z/data=!3m1!4b1!4m6!3m5!1s0x865b4b144a13f911:0xf29b3922fac942ba!8m2!3d30.2305155!4d-97.8097468!16s%2Fm%2F0k0bh48'),
  ('Gupton Stadium',
   '200 Gupton Way Drive, Cedar Park, TX 78613',
   'https://maps.google.com/?q=200+Gupton+Way+Drive+Cedar+Park+TX+78613'),
  ('Chaparral Stadium',
   '4100 Westbank Drive, Austin, TX 78746',
   'https://maps.google.com/?q=4100+Westbank+Drive+Austin+TX+78746'),
  ('James Bowie High School',
   '4103 W Slaughter Lane, Austin, TX 78749',
   'https://maps.google.com/?q=4103+W+Slaughter+Lane+Austin+TX+78749'),
  ('Lake Belton High School',
   '9809 Prairie View Road, Temple, TX 76502',
   'https://maps.google.com/?q=9809+Prairie+View+Road+Temple+TX+76502'),
  ('Rouse High School',
   '1222 Raider Way, Leander, TX 78641',
   'https://maps.google.com/?q=1222+Raider+Way+Leander+TX+78641'),
  ('Vista Ridge High School',
   '200 S Vista Ridge Boulevard, Cedar Park, TX 78613',
   'https://maps.google.com/?q=200+S+Vista+Ridge+Boulevard+Cedar+Park+TX+78613'),
  ('Lake Travis High School',
   '3324 Ranch Road 620 S, Austin, TX 78738',
   'https://maps.google.com/?q=3324+Ranch+Road+620+S+Austin+TX+78738'),
  ('Cedar Ridge High School',
   '2801 Gattis School Road, Round Rock, TX 78664',
   'https://maps.google.com/?q=2801+Gattis+School+Road+Round+Rock+TX+78664'),
  ('Stony Point High School',
   '1801 Tiger Trail, Round Rock, TX 78664',
   'https://maps.google.com/?q=1801+Tiger+Trail+Round+Rock+TX+78664'),
  ('Westlake High School',
   '4100 Westbank Drive, Austin, TX 78746',
   'https://maps.google.com/?q=4100+Westbank+Drive+Austin+TX+78746'),
  ('Westwood High School',
   '12400 Mellow Meadow Drive, Austin, TX 78750',
   'https://maps.google.com/?q=12400+Mellow+Meadow+Drive+Austin+TX+78750'),
  ('Phil''s Ice House (183)',
   '13265 N US-183, Austin, TX 78750',
   'https://maps.google.com/?q=13265+N+US-183+Austin+TX+78750'),
  ('Morningside Pool (Avery Ranch)',
   '10121 Morgan Creek Drive, Austin, TX 78717',
   'https://maps.google.com/?q=10121+Morgan+Creek+Dr+Austin+TX+78717')
on conflict (name) do nothing;

-- ── backfill: location string -> venue ──────────────────────────────────────
with mapping (loc, venue_name) as (values
  -- 2026-27 games
  ('Maverick Stadium',                   'McNeil High School'),
  ('KRAC',                               'Kelly Reeves Athletic Complex'),
  ('Dragon Stadium',                     'Round Rock High School Dragon Stadium'),
  ('Burger Stadium',                     'Toney Burger Stadium'),
  ('Gupton',                             'Gupton Stadium'),
  ('Chaparral',                          'Chaparral Stadium'),
  ('Bowie HS',                           'James Bowie High School'),
  ('Lake Belton HS',                     'Lake Belton High School'),
  ('Rouse HS',                           'Rouse High School'),
  ('Vista Ridge HS',                     'Vista Ridge High School'),
  ('Lake Travis HS',                     'Lake Travis High School'),
  ('Cedar Ridge HS',                     'Cedar Ridge High School'),
  ('Stony Point HS',                     'Stony Point High School'),
  ('Westlake HS',                        'Westlake High School'),
  ('Westwood HS',                        'Westwood High School'),
  -- 2025-26 spellings of the same places (see the alias warning above)
  ('Gupton Stadium',                     'Gupton Stadium'),
  ('Round Rock HS',                      'Round Rock High School Dragon Stadium')
)
update games g
   set venue_id = v.id
  from mapping m
  join venues v on v.name = m.venue_name
 where g.location = m.loc
   and g.venue_id is null;

with mapping (loc, venue_name) as (values
  ('McNeil High School',                 'McNeil High School'),
  ('McNeil High School Stadium',         'McNeil High School'),
  ('McNeil High School Cafeteria',       'McNeil High School'),
  ('Team Room G204, McNeil High School', 'McNeil High School'),
  ('Phil’s Ice House (183)',             'Phil''s Ice House (183)'),
  ('Morningside Pool (Avery Ranch)',     'Morningside Pool (Avery Ranch)')
)
update events e
   set venue_id = v.id
  from mapping m
  join venues v on v.name = m.venue_name
 where e.location = m.loc
   and e.venue_id is null;

-- One source for the link: the venue now owns it.
update events set location_url = null where venue_id is not null;

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int; leftover text;
begin
  select count(*) into n from venues;
  if n < 17 then raise exception 'expected at least 17 venues, got %', n; end if;

  -- Every CURRENT-season game that names a place must resolve to one.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from games
   where year = '2026-27' and location is not null and venue_id is null;
  if n > 0 then
    raise exception '% 2026-27 game rows have an unmatched venue: %', n, leftover;
  end if;

  -- Same for every event that names a place.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from events
   where coalesce(location, '') <> '' and venue_id is null;
  if n > 0 then
    raise exception '% event rows have an unmatched venue: %', n, leftover;
  end if;

  -- No event may carry a link in two places any more.
  select count(*) into n from events where venue_id is not null and location_url is not null;
  if n <> 0 then raise exception '% events still carry a stale location_url', n; end if;

  -- Last season is expected to have leftovers; say how many rather than failing.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from games
   where year <> '2026-27' and location is not null and venue_id is null;
  raise notice '% archived (non-2026-27) game rows have no venue: %', n, coalesce(leftover, 'none');
end $$;

commit;

-- Verification:
--   select v.name, count(g.id) from venues v left join games g on g.venue_id = v.id
--    where g.year = '2026-27' group by 1 order by 2 desc;
--   -- and the gap check to run after ANY new game is added:
--   select distinct location from games where year = '2026-27' and venue_id is null
--     and location is not null;

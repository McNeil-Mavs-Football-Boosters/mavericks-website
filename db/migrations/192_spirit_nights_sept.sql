-- 192_spirit_nights_sept.sql
--
-- Two September spirit nights, from Jeremy 2026-09-08:
--
--   Mon Sep 14, 6:00-8:00 PM   The League Kitchen & Tavern (Avery and Parmer)
--   Wed Sep 30, 6:00-8:00 PM   Mighty Fine Burgers (Arbor Walk)
--
-- The point of putting these on the site is a stable URL Jeremy can hand to John
-- Mark Edwards for Mav Mail and Debby Mata for social, and link from the weekly
-- newsletter, instead of retyping the details into three places.
--
-- ── MODELLED ON `community-night-phils-amys-2026`, CONFIRMED BY JEREMY ──
-- That event is the club's existing spirit-night precedent and he approved
-- matching it. Its description carries the mechanic that makes these work:
-- **"Mention McNeil Football at the register"**. That line is not decoration --
-- a spirit night where nobody mentions the school raises nothing, and the
-- restaurant has no way to attribute the sale. It appears in both descriptions
-- here for the same reason. 🚫 Do not trim it for brevity.
--
-- ⚠️ NO PERCENTAGE IS STATED, MATCHING THE PHIL'S EVENT. Jeremy did not supply
-- one, and "a portion of your purchase" is both honest and the standard phrasing
-- for these. Do not invent a number; if a restaurant confirms one, it can be
-- added to the description in a one-line update.
--
-- ── ADDRESSES CAME FROM THE CLUB'S OWN FILE, NOT A SEARCH ──
-- Both restaurants are already in `lib/coach-meals.ts` as coaches-lunch
-- locations, with addresses and phone numbers the club uses in production:
--   The League      10526 W Parmer Ln, Austin, TX 78717   (Avery and Parmer)
--   Mighty Fine     10515 N Mopac Expy, Austin, TX 78759  (Mopac and Braker)
-- ⚠️ Jeremy called the second one "Arbor Walk" and coach-meals calls it "Mopac
-- and Braker". **Same store** -- Arbor Walk is the shopping centre at Mopac and
-- Braker and 10515 N Mopac Expy is its address. Recorded because the two names
-- look like two locations and a future reader will wonder.
--
-- ⚠️ `venues.name` IS UNIQUE. The League shares its street address with Tony C's
-- (they are next door, noted in `coach-meals.ts`), and a shared address is fine
-- because only the name is constrained.
--
-- ⚠️ TONY C'S IS **NOT** IN `venues`, AND A GUARD HERE FIRED ON THE ASSUMPTION
-- THAT IT WAS. `venues` holds stadiums; the only restaurant in it before this
-- migration was Phil's Ice House, added for the Aug 4 community night. Every
-- other restaurant the club deals with lives in `lib/coach-meals.ts` as a code
-- constant and has no row. So after this runs there is exactly ONE venue at
-- 10526 W Parmer Ln, not two. Recorded so a later reader does not conclude a
-- Tony C's row went missing.
--
-- ── BOTH ARE GOLD SPONSORS, WHICH IS WHY THIS IS WORTH DOING ──
-- `sponsors` carries "The League Kitchen & Tavern" and "Mighty Fine Burgers".
-- Sending families to a sponsor's till is the recognition they paid for. Not
-- stated in the copy (the Phil's precedent does not), but it is the reason these
-- two restaurants and not others.
--
-- ⚠️ THERE IS NO "SHOW ON HOMEPAGE" FLAG AND NONE IS NEEDED. The homepage calls
-- `getUpcomingEvents(3, {includeGames: true, gameLevels: ["varsity"]})`, which
-- merges published events with varsity games and takes the next three by date.
-- `featured` exists on `events` but the homepage query does not read it, so
-- setting it would do nothing. Publishing is sufficient. Sep 14 lands third
-- (behind the Sep 11 varsity game and ahead of Sep 18) and shows immediately;
-- Sep 30 is sixth in line and surfaces once Sep 14 passes.
--
-- DB-ONLY, NO DEPLOY. /events, the homepage and the ICS read at request time.
--
-- Rollback: 192_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug in ('spirit-night-the-league-2026-09-14',
                  'spirit-night-mighty-fine-2026-09-30');
  if n <> 0 then raise exception 'spirit night events already exist (found %)', n; end if;
end $$;

insert into venues (name, address, maps_url)
values
  ('The League Kitchen & Tavern',
   '10526 W Parmer Ln, Austin, TX 78717',
   'https://www.google.com/maps/search/?api=1&query=The+League+Kitchen+%26+Tavern%2C+10526+W+Parmer+Ln%2C+Austin%2C+TX+78717'),
  ('Mighty Fine Burgers (Arbor Walk)',
   '10515 N Mopac Expy, Austin, TX 78759',
   'https://www.google.com/maps/search/?api=1&query=Mighty+Fine+Burgers%2C+10515+N+Mopac+Expy%2C+Austin%2C+TX+78759')
on conflict (name) do nothing;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Spirit Night at The League',
  'spirit-night-the-league-2026-09-14',
  'Join the Mavs for a Spirit Night at The League Kitchen & Tavern (Avery and Parmer) on Monday, September 14, 6:00-8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team. Everyone in your party counts, so bring the whole family.',
  timestamptz '2026-09-14 18:00 America/Chicago',
  timestamptz '2026-09-14 20:00 America/Chicago',
  'The League (Avery and Parmer)',
  v.id,
  'published'
from venues v where v.name = 'The League Kitchen & Tavern';

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Spirit Night at Mighty Fine',
  'spirit-night-mighty-fine-2026-09-30',
  'Join the Mavs for a Spirit Night at Mighty Fine Burgers at Arbor Walk on Wednesday, September 30, 6:00-8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team. Everyone in your party counts, so bring the whole family.',
  timestamptz '2026-09-30 18:00 America/Chicago',
  timestamptz '2026-09-30 20:00 America/Chicago',
  'Mighty Fine (Arbor Walk)',
  v.id,
  'published'
from venues v where v.name = 'Mighty Fine Burgers (Arbor Walk)';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug in ('spirit-night-the-league-2026-09-14',
                    'spirit-night-mighty-fine-2026-09-30')
     and e.status = 'published' and e.ends_at is not null;
  if n <> 2 then raise exception 'expected 2 published spirit nights with venues, found %', n; end if;

  -- The mechanic that makes a spirit night raise anything must be in both.
  select count(*) into n from events
   where slug like 'spirit-night-%' and description like '%Mention McNeil Football at the register%';
  if n <> 2 then raise exception 'the "mention McNeil Football" line is missing from % of them', 2 - n; end if;

  -- Both run 6:00-8:00 PM Central.
  select count(*) into n from events
   where slug like 'spirit-night-%'
     and extract(hour from starts_at at time zone 'America/Chicago') = 18
     and extract(hour from ends_at at time zone 'America/Chicago') = 20;
  if n <> 2 then raise exception 'spirit night times are not 6-8 PM (%)', n; end if;

  -- Exactly one venue at that address: The League. See the note above on why
  -- Tony C's is not a second one. This still catches a duplicate insert, which
  -- is what the check is for -- `on conflict (name) do nothing` would otherwise
  -- make a re-run look successful while quietly adding nothing.
  select count(*) into n from venues where address = '10526 W Parmer Ln, Austin, TX 78717';
  if n <> 1 then raise exception 'expected 1 venue at The League address, found %', n; end if;
end $$;

commit;

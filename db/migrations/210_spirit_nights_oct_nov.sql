-- 210_spirit_nights_oct_nov.sql
--
-- Three confirmed spirit nights, from Kendra's email to Jeremy 2026-09-22
-- ("Please add the following confirmed Spirit Nights to the Events page"):
--
--   Wed Oct 14, 5:00-8:00 PM   Pok-e-Jo's Smokehouse        2121 Parmer Lane, Austin, TX 78727
--   Mon Oct 26, 5:00-8:00 PM   Raising Cane's Chicken Fingers  12901 N Interstate Hwy 35, Bldg 21, Austin, TX 78753
--   Mon Nov 9,  5:00-8:00 PM   Raising Cane's Chicken Fingers  (same store)
--
-- Weekdays verified with `date`, not assumed: Oct 14 2026 is a Wednesday, Oct 26
-- and Nov 9 are Mondays. Checked before writing: no `events` row and no `games`
-- row on any of the three dates, so nothing is being scheduled on top of a game.
--
-- ── SAME SHAPE AS 192/193/194, WHICH IS THE CLUB'S SPIRIT-NIGHT TEMPLATE ──
-- Same columns, same "published" status, same copy with the two sentences that
-- do the work carried verbatim and asserted below:
--   🚨 "Please mention McNeil Football at the register." -- the whole fundraiser
--      (193). A night where nobody says it raises nothing.
--   ⚠️ "If you do not have one, you can buy one there." -- an OPERATIONAL PROMISE
--      that the merch table is on site (193). Three more nights now carry it, so
--      three more nights need a person with the merch. Flagged to Jeremy again.
-- No percentage stated, matching 192: Kendra's email gives none.
--
-- ⚠️ 5:00-8:00 PM, NOT 6:00-8:00. The two September nights were 6-8; Kendra's
-- email says 5 pm - 8 pm for all three. The verify block checks hour 17, and the
-- description prose says 5:00-8:00 to match (194's rule: prose and timestamp
-- move together).
--
-- ── ADDRESSES ARE KENDRA'S, TRANSCRIBED, NOT SEARCHED ──
-- Neither restaurant is in `lib/coach-meals.ts` or `venues`, so unlike 192 there
-- is no club file to cross-check against. Kendra's email is the club's source
-- and the addresses are taken as she wrote them (punctuation normalised, "BLDG"
-- -> "Bldg"). The short `location` labels use only what her text supports:
-- "Parmer" for Pok-e-Jo's and "N I-35" for Cane's -- no shopping-centre or
-- cross-street name was added because none was given.
--
-- ── BOTH ARE SPONSORS (same tier row), which is the point ──
-- `sponsors` carries "Pok-E-Jo's Smokehouse" and "Raising Cane's Chicken
-- Fingers". Sending families to a sponsor's till is the recognition they paid
-- for. Kendra countered Pok-e-Jo's at platinum for the JV/freshman banquet and
-- Cane's is a two-year agreement (booster_club_info.md); neither fact is in the
-- copy, matching precedent.
--
-- ⚠️ ONE VENUE ROW FOR CANE'S, TWO EVENTS POINT AT IT. `venues.name` is unique
-- and both nights are the same store, so the second event reuses the row. That
-- is the correct shape: a later address fix touches one row, not two.
--
-- ⚠️ SLUGS CARRY THE DATE AND WILL NOT BE RENAMED IF A DATE MOVES (194). Stable
-- URL is what Kendra, John Mark Edwards (Mav Mail) and Debby Mata (social) get.
--
-- DB-ONLY, NO DEPLOY. /events, /events/[slug], the homepage and the ICS feed
-- read at request time (`/events.ics` is cached an hour; append ?cb= to verify).
--
-- Rollback: 210_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug in ('spirit-night-pok-e-jos-2026-10-14',
                  'spirit-night-raising-canes-2026-10-26',
                  'spirit-night-raising-canes-2026-11-09');
  if n <> 0 then raise exception 'spirit night events already exist (found %)', n; end if;

  select count(*) into n from venues
   where name in ('Pok-e-Jo''s Smokehouse (Parmer)', 'Raising Cane''s Chicken Fingers (N I-35)');
  if n <> 0 then raise exception 'venue rows already exist (found %)', n; end if;

  -- Nothing else is on these dates (checked by hand before writing; asserted so a re-run
  -- against a changed DB says so instead of stacking).
  select count(*) into n from events
   where starts_at::date in (date '2026-10-14', date '2026-10-26', date '2026-11-09');
  if n <> 0 then raise exception '% events already sit on the three dates', n; end if;
end $$;

insert into venues (name, address, maps_url)
values
  ('Pok-e-Jo''s Smokehouse (Parmer)',
   '2121 Parmer Lane, Austin, TX 78727',
   'https://www.google.com/maps/search/?api=1&query=Pok-e-Jo%27s+Smokehouse%2C+2121+Parmer+Lane%2C+Austin%2C+TX+78727'),
  ('Raising Cane''s Chicken Fingers (N I-35)',
   '12901 N Interstate Hwy 35, Bldg 21, Austin, TX 78753',
   'https://www.google.com/maps/search/?api=1&query=Raising+Cane%27s+Chicken+Fingers%2C+12901+N+Interstate+Hwy+35%2C+Austin%2C+TX+78753');

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Spirit Night at Pok-e-Jo''s',
  'spirit-night-pok-e-jos-2026-10-14',
  'Join the Mavs for a Spirit Night at Pok-e-Jo''s Smokehouse on Parmer Lane on Wednesday, October 14, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
  timestamptz '2026-10-14 17:00 America/Chicago',
  timestamptz '2026-10-14 20:00 America/Chicago',
  'Pok-e-Jo''s (Parmer)',
  v.id,
  'published'
from venues v where v.name = 'Pok-e-Jo''s Smokehouse (Parmer)';

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Spirit Night at Raising Cane''s',
  'spirit-night-raising-canes-2026-10-26',
  'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, October 26, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
  timestamptz '2026-10-26 17:00 America/Chicago',
  timestamptz '2026-10-26 20:00 America/Chicago',
  'Raising Cane''s (N I-35)',
  v.id,
  'published'
from venues v where v.name = 'Raising Cane''s Chicken Fingers (N I-35)';

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Spirit Night at Raising Cane''s',
  'spirit-night-raising-canes-2026-11-09',
  'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, November 9, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
  timestamptz '2026-11-09 17:00 America/Chicago',
  timestamptz '2026-11-09 20:00 America/Chicago',
  'Raising Cane''s (N I-35)',
  v.id,
  'published'
from venues v where v.name = 'Raising Cane''s Chicken Fingers (N I-35)';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug in ('spirit-night-pok-e-jos-2026-10-14',
                    'spirit-night-raising-canes-2026-10-26',
                    'spirit-night-raising-canes-2026-11-09')
     and e.status = 'published' and e.ends_at is not null;
  if n <> 3 then raise exception 'expected 3 published spirit nights with venues, found %', n; end if;

  -- 5:00-8:00 PM Central on all three, and the prose agrees.
  select count(*) into n from events
   where slug in ('spirit-night-pok-e-jos-2026-10-14',
                  'spirit-night-raising-canes-2026-10-26',
                  'spirit-night-raising-canes-2026-11-09')
     and extract(hour from starts_at at time zone 'America/Chicago') = 17
     and extract(hour from ends_at at time zone 'America/Chicago') = 20
     and description like '%5:00-8:00 PM%';
  if n <> 3 then raise exception 'new spirit night times are not 5-8 PM on all three (%)', n; end if;

  -- Day names in the prose match the timestamps.
  select count(*) into n from events
   where (slug = 'spirit-night-pok-e-jos-2026-10-14'     and description like '%Wednesday, October 14%')
      or (slug = 'spirit-night-raising-canes-2026-10-26' and description like '%Monday, October 26%')
      or (slug = 'spirit-night-raising-canes-2026-11-09' and description like '%Monday, November 9%');
  if n <> 3 then raise exception 'a day name in the prose does not match (%)', n; end if;

  -- The two working sentences are on every spirit night, old and new: five total.
  select count(*) into n from events
   where slug like 'spirit-night-%'
     and description like '%mention McNeil Football at the register%'
     and description like '%tells them your purchase counts%'
     and description like '%Wear your Mav shirt%'
     and description like '%you can buy one there%';
  if n <> 5 then raise exception 'expected 5 spirit nights carrying the mention and shirt lines, found %', n; end if;

  -- One Cane's venue, two events on it.
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where v.name = 'Raising Cane''s Chicken Fingers (N I-35)';
  if n <> 2 then raise exception 'expected 2 events on the Cane''s venue, found %', n; end if;

  -- The September two are untouched.
  select count(*) into n from events
   where (slug = 'spirit-night-the-league-2026-09-14'  and starts_at = timestamptz '2026-09-15 18:00 America/Chicago')
      or (slug = 'spirit-night-mighty-fine-2026-09-30' and starts_at = timestamptz '2026-09-30 18:00 America/Chicago');
  if n <> 2 then raise exception 'a September spirit night changed (%)', n; end if;
end $$;

commit;

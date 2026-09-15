-- 197_mavs_and_moms_senior_photo_day.sql
--
-- Mavs and Moms Senior Photo Day, Sun 20 Sep 2026, 12:30 p.m., Varsity Locker
-- Room. Jeremy 2026-09-15, relaying the post already on the parent group page
-- and asking for it on the site "in the next day or so".
--
-- ── THE INCLUSIVE SENTENCE IS THE POINT OF THIS EVENT'S COPY ──
-- 🚨 Jeremy asked for it explicitly: "I'd like to include some text that's a bit
-- sensitive for boys who don't have a solid mom figure." The line is
-- **"Bring your mom, stepmom, grandma, aunt, or whoever has been your person.
-- We want them there with you."** 🚫 DO NOT trim it to "bring your mom" for
-- brevity, and do not cut the second sentence, which is what turns a list of
-- options into an invitation. A senior with no mother in the picture reads this
-- page and decides whether the event is for him; that is the whole job of the
-- paragraph.
--
-- ⚠️ THE ATTIRE LINE IS DELIBERATELY NOT "MOMS WEAR". The source copy reads
-- "You: blue jersey and jeans. Her: plain white top and jeans." Rendering that
-- as "Moms wear a plain white top" would re-narrow the audience two sentences
-- after widening it, which is exactly the thing being guarded against. It reads
-- "She wears", which covers a grandmother or an aunt without comment.
--
-- The event's NAME keeps "Mavs and Moms" because that is what the tradition is
-- called and what the flyer says; renaming the tradition was not asked for and
-- would disconnect the page from every other mention. The copy does the work.
--
-- ── ends_at IS NULL, ON PURPOSE, AND THAT IS A SUPPORTED STATE ──
-- No end time was given. Every existing `events` row happens to have one, so
-- this is the first null, but it is a designed case rather than an accident:
-- `formatEventWhen` renders "September 20 @ 12:30 PM" with no range, and
-- `lib/queries/events.ts` falls back to END OF THE EVENT'S DAY for upcoming/past
-- filtering (the comment there calls that fallback load-bearing). **Inventing a
-- finish time would put a fact in front of a family that nobody supplied** --
-- same rule as the freshman/JV pickup time, which was left null for weeks rather
-- than guessed.
--
-- ⚠️ NO COVER IMAGE, AND THE FLYER IS THE REASON, NOT AN OVERSIGHT.
-- Jeremy supplied the flyer and `events.cover_image_url` exists for exactly this.
-- It is still null here because **both renderers force `aspect-video` with
-- `object-cover`** (`app/events/[slug]/page.tsx` and
-- `components/events/EventListView.tsx`) and the flyer is **820x1024 PORTRAIT**.
-- Covering a 16:9 box from a 0.8 ratio source keeps only the middle ~45% of the
-- image: the title crops off the top and the entire WHO / WHAT / WHEN / WHERE /
-- ATTIRE block crops off the bottom, leaving a band of horseshoe artwork. The
-- column has never been used by any row, so this would have been its first
-- outing and its first bug. Options, for whoever picks this up: a landscape
-- version of the flyer, or a code change to let a portrait cover render
-- unclipped. Raised with Jeremy 2026-09-15.
--
-- ⚠️ EVERY FACT ON THE FLYER IS IN THE DESCRIPTION TEXT REGARDLESS. Standing
-- rule from the newsletter's flyer handling: never let a detail live only in an
-- image. Here it is load-bearing twice over, because there is no image.
--
-- ⚠️ THE DESCRIPTION IS PLAIN PROSE, NO MARKDOWN AND NO URL, and 156 is the
-- reason: only the detail page runs `description` through ReactMarkdown, while
-- the /events list card and the ICS feed render it as plain text, so a markdown
-- link shows up literally in every subscribed calendar.
--
-- ⚠️ IT COLLIDES WITH THE COACHES SUNDAY LUNCH DROP-OFF. That volunteer delivers
-- to McNeil between 12:30 and 1:00 the same day (Sep 20, Mighty Fine, already
-- claimed). Same building, same half hour. Not a conflict the site can resolve
-- and not a reason to move either one, but if the two people are the same
-- person, somebody needs to know. Flagged to Jeremy.
--
-- Venue is the existing McNeil High School row (5720 McNeil Drive), the same one
-- picture day and helmet decal night use, with the room in `location`.
--
-- DB-ONLY, NO DEPLOY. /events, the homepage and the ICS read at request time.
--
-- Rollback: 197_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'mavs-and-moms-senior-photo-day-2026';
  if n <> 0 then raise exception 'the photo day event already exists'; end if;

  select count(*) into n from venues where name = 'McNeil High School';
  if n <> 1 then raise exception 'expected exactly 1 McNeil High School venue, found %', n; end if;
end $$;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Mavs and Moms Senior Photo Day',
  'mavs-and-moms-senior-photo-day-2026',
  'Seniors, it is almost time for Mavs and Moms Senior Photo Day, a Mavs tradition. '
  'Join us Sunday, September 20 at 12:30 p.m. in the Varsity Locker Room. '
  'Bring your mom, stepmom, grandma, aunt, or whoever has been your person. We want them there with you. '
  'You wear a blue jersey and jeans. She wears a plain white top and jeans. '
  'Let''s celebrate you.',
  timestamptz '2026-09-20 12:30 America/Chicago',
  null,
  'Varsity Locker Room',
  v.id,
  'published'
from venues v where v.name = 'McNeil High School';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'mavs-and-moms-senior-photo-day-2026'
     and e.status = 'published'
     and e.starts_at = timestamptz '2026-09-20 12:30 America/Chicago'
     and e.ends_at is null
     and e.location = 'Varsity Locker Room'
     and v.name = 'McNeil High School';
  if n <> 1 then raise exception 'the photo day event did not land as expected (%)', n; end if;

  -- 🚨 THE INCLUSIVE LINE IS ASSERTED, BOTH HALVES. This is the one thing Jeremy
  -- asked for by name and the one thing a later "tighten the copy" pass would
  -- take out first.
  select count(*) into n from events
   where slug = 'mavs-and-moms-senior-photo-day-2026'
     and description like '%whoever has been your person%'
     and description like '%We want them there with you%';
  if n <> 1 then raise exception 'the inclusive sentence is missing or truncated'; end if;

  -- The attire line must not re-narrow to mothers.
  select count(*) into n from events
   where slug = 'mavs-and-moms-senior-photo-day-2026'
     and description like '%She wears a plain white top%'
     and description not like '%Moms wear%';
  if n <> 1 then raise exception 'the attire line re-narrows the audience'; end if;

  -- Both attire halves survived, and the day and time are in the prose as well
  -- as the timestamp (the ICS and the list card show the prose).
  select count(*) into n from events
   where slug = 'mavs-and-moms-senior-photo-day-2026'
     and description like '%blue jersey and jeans%'
     and description like '%Sunday, September 20 at 12:30 p.m.%'
     and description like '%Varsity Locker Room%';
  if n <> 1 then raise exception 'a flyer fact is missing from the description'; end if;

  -- Plain prose only: no markdown link syntax, no bare URL. See 156.
  select count(*) into n from events
   where slug = 'mavs-and-moms-senior-photo-day-2026'
     and (description like '%](%' or description like '%http%');
  if n <> 0 then raise exception 'the description contains markdown or a URL'; end if;

  -- Nothing else already claimed that Sunday lunchtime in `events`.
  select count(*) into n from events
   where status = 'published'
     and starts_at >= timestamptz '2026-09-20 00:00 America/Chicago'
     and starts_at <  timestamptz '2026-09-21 00:00 America/Chicago';
  if n <> 1 then raise exception 'expected exactly 1 published event on Sep 20, found %', n; end if;
end $$;

commit;

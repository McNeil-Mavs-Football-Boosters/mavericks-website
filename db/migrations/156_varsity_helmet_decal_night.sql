-- 156_varsity_helmet_decal_night.sql
--
-- Coach's flyer, Jeremy 2026-08-24: parents and guardians put decals on the
-- varsity helmets in the McNeil football locker room, Thu Aug 27, 5:00-6:00 p.m.
--
-- ⚠️ NO COVER IMAGE, AND THAT IS JEREMY'S CALL (2026-08-24), NOT AN OVERSIGHT.
-- The flyer he sent is portrait (1179x1842, aspect 0.64). Both places the site
-- renders `events.cover_image_url` - the detail page and the `/events` list card -
-- force `aspect-video` with `object-cover`, so a portrait image is centre-cropped
-- to a horizontal band: the "MCNEIL MAVERICKS" headline off the top and the date,
-- time and locker-room line off the bottom, which is the entire useful content.
-- Offered a render fix (letterbox the card, natural aspect on the detail page) or
-- a hand-made 16:9 crop, he chose neither. The flyer goes in the newsletter, where
-- the layout is ours. **`cover_image_url` is still NULL on every event row in this
-- table** - this event did not become the first user of that field.
--
-- ⚠️ THE DESCRIPTION IS DELIBERATELY PLAIN PROSE WITH NO MARKDOWN. Only the detail
-- page runs `description` through ReactMarkdown; the `/events` list card and the ICS
-- feed render it as PLAIN TEXT, so a markdown link shows up literally as
-- `[text](https://...)` in every subscribed calendar. Same lesson as migration 150.
--
-- ⚠️ THE 'McNeil High School' VENUE HAS NO COORDINATES, ON PURPOSE, so this event's
-- ICS entry carries no GEO line. That is the standing rule, not a gap to fill: a
-- coordinate only ever comes from a Maps link a human opened, and NULL is the honest
-- value otherwise. All eight existing campus events behave the same way. Note that
-- 'Maverick Stadium' shares this exact address (5720 McNeil Drive) and DOES have a
-- verified pin - do not "upgrade" campus events onto it. It is the stadium; the
-- locker room, cafeteria and team room are not, and the venue rows say what they mean.
--
-- Timing worth knowing rather than fixing: this runs 5:00-6:00 p.m. and the JV game
-- kicks off at 6:00 p.m. at Maverick Stadium on the SAME campus, so a varsity family
-- can do both back to back. The freshman game the same evening is 5:00 p.m. at the
-- Burger Annex in south Austin, ~20 miles away, so a family with both a varsity and
-- a freshman athlete genuinely cannot do both. Nothing to solve in the schema; it is
-- called out in the newsletter instead.

begin;

insert into events (
  title, slug, description, starts_at, ends_at, location, venue_id, status, featured
)
values (
  'Varsity Helmet Decal Night',
  'varsity-helmet-decal-night-2026',
  'Parents and guardians, help us get our Varsity Mavericks game-day ready by '
  || 'putting decals on your athlete''s helmet. This is for all varsity athletes, '
  || 'ahead of the season opener at Austin Bowie the following night. Drop in any '
  || 'time in the hour. If you are staying for the JV game, it kicks off at 6:00 '
  || 'p.m. at Maverick Stadium, right as this wraps up.',
  '2026-08-27 17:00:00 America/Chicago',
  '2026-08-27 18:00:00 America/Chicago',
  'McNeil Football Locker Room',
  (select id from venues where name = 'McNeil High School'),
  'published',
  false
);

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'varsity-helmet-decal-night-2026'
     and e.status = 'published'
     and e.starts_at = '2026-08-27 17:00:00 America/Chicago'
     and e.ends_at   = '2026-08-27 18:00:00 America/Chicago'
     and e.location = 'McNeil Football Locker Room'
     and v.name = 'McNeil High School';
  if n <> 1 then raise exception 'decal night row is not as expected (matched % rows)', n; end if;

  -- The description must stay plain text: no markdown link or image syntax, because
  -- the list card and the ICS feed do not render markdown.
  select count(*) into n from events
   where slug = 'varsity-helmet-decal-night-2026'
     and (description like '%](%' or description like '%http%');
  if n <> 0 then raise exception 'decal night description contains markup or a bare URL'; end if;

  -- Nothing in this table uses cover_image_url yet, and 156 did not change that.
  select count(*) into n from events where cover_image_url is not null;
  if n <> 0 then raise exception '% events now carry a cover image; 156 was meant to add none', n; end if;
end $$;

commit;

-- 131_meet_the_mavs_photos.sql
--
-- Photo album for the Aug 14 Meet the Mavs, supplied by Jeremy 2026-08-16. Second
-- use of the `events.photos_url` mechanism from migration 114 (the Aug 7 pool
-- party was the first), so this is a one-column UPDATE and nothing else - no new
-- resource_links row. 114's "Event Photos" entry already points at the past-events
-- list and covers every album from here on.
--
-- Link verified before writing: https://photos.app.goo.gl/fFYzH6d5hxPfyKok6
-- resolves 200 to photos.google.com/share/... and the album's own title is
-- "Meet the Mavs 2026 - 2027", og:title "Meet the Mavs 2026 - 2027 · Friday,
-- Aug 14" - the right event, not a same-name album from another season.
--
-- ⚠️ Carries forward 114's privacy note, unchanged: a photos.app.goo.gl link is
-- public to anyone holding it, and these are photos of minors. Publishing it here
-- makes the album genuinely public. Jeremy owns club photos and made the call for
-- the pool party and again for this one. Pulling it back down is
--   update events set photos_url = null where slug = 'meet-the-mavs-2026';
-- with no deploy - `/events` and the detail page both hide the affordance on null.
--
-- ⚠️ Album links rot silently. If the album is deleted or unshared, the site shows
-- a dead "View Photos" button with no signal. Nothing here can detect that.

begin;

update events
   set photos_url = 'https://photos.app.goo.gl/fFYzH6d5hxPfyKok6'
 where slug = 'meet-the-mavs-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'meet-the-mavs-2026'
     and photos_url = 'https://photos.app.goo.gl/fFYzH6d5hxPfyKok6';
  if n <> 1 then raise exception 'meet-the-mavs-2026 photos_url not set (matched % rows)', n; end if;
end $$;

commit;

-- /events and /events/[slug] read at request time: live with no deploy.
-- Verification:
--   select slug, photos_url from events where photos_url is not null;

-- 114_event_photos.sql
--
-- Photo albums for past events. Jeremy 2026-08-08, prompted by the Aug 7 pool
-- party.
--
-- DESIGN: the album URL lives on the EVENT, and `/resources` gets exactly ONE
-- durable row pointing at the past-events list. The tempting alternative — a
-- resource_links row per album, mirroring the existing "Game Photos" row — was
-- rejected: Game Photos works because it is one permanent destination, whereas
-- event albums accrue one per event forever. That turns Forms & Links into a
-- junk drawer and adds a manual step someone eventually forgets. One row that
-- never needs touching, plus per-event links set once at album-creation time.
--
-- ⚠️ PRIVACY, raised with Jeremy before shipping: a photos.app.goo.gl link is
-- public to anyone holding it, and these are photos of minors. Publishing it on
-- the site makes the album genuinely public. Jeremy owns club photos and made
-- the call. `photos_url` is NULLABLE and the UI renders nothing when it is null,
-- so pulling an album back down is a one-line UPDATE with no deploy.
--
-- ⚠️ Album links rot silently. If someone deletes or unshares an album, the site
-- shows a dead link with no signal. Nothing here can detect that.

begin;

alter table events
  add column if not exists photos_url text;

comment on column events.photos_url is
  'Public photo-album URL for this event (e.g. a Google Photos shared album). '
  'NULL = no album; every render site must hide its affordance when null. '
  'Public to anyone with the link — do not set for events where that is not intended.';

-- The Aug 7 pool party album.
update events
set photos_url = 'https://photos.app.goo.gl/ojcaEm5ndmngmAak9'
where slug = 'pool-party-2026';

-- One durable Forms & Links entry. Points at the past-events list rather than a
-- single album, so this row is correct forever and no future album needs a new
-- row. Sits under News & Communications next to Game Photos (sort_order 4).
-- icon_hint 'photo' -> lucide Camera, registered by migration 051.
insert into resource_links (label, url, description, section, sort_order, icon_hint, active)
select
  'Event Photos',
  '/events?filter=past',
  'Photo albums from past Booster Club events. Open a past event to view its album.',
  'communications',
  5,
  'photo',
  true
where not exists (
  select 1 from resource_links where label = 'Event Photos'
);

commit;

-- Verification:
--   select slug, photos_url from events where photos_url is not null;
--   select label, url, section, sort_order from resource_links where label = 'Event Photos';
--
-- Both /events and /resources read at request time, so this goes live with no
-- deploy once the rendering code ships.

-- 185_game_photos_2026_bowie.sql
--
-- Repoints the single "Game Photos" row on /resources from last season's index
-- doc to this season's first album. Jeremy sent the link 2026-09-06 and chose
-- "replace previous link" when given the alternatives.
--
--   was:  https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0/edit?tab=t.0#heading=h.gf4l39u0yuz6
--   now:  https://photos.google.com/share/AF1QipPF3TczLboM6HbLAFW-cgJ2dISqbpe_3SMqE5ZgkMAADhMfb9ol8ZaEy4jQKVd1bQ?key=aHNnSG9pQnh6QzhOczJRZ05LZ1gtS1hlMXlwYWJ3
--
-- ── WHY THE OLD LINK HAD TO GO ──
-- The doc is titled "2025-2026 McNeil Football Photos", is owned by
-- djohnsonjr@gmail.com (a parent, not the club), was last modified 2026-01-20,
-- and its newest entry is the January banquet. Nothing from 2026-27 is in it and
-- nobody here can add anything to it. A row labelled "Game Photos" on the
-- current season's site that leads only to last season's games is worse than a
-- row that leads to one real album from this season.
--
-- 🚫 THE 2025-26 DOC IS NOT DELETED, IT IS RECORDED HERE AND IN THE ROLLBACK.
-- It is still the only index of last season's albums, and it is somebody else's
-- document. If an archive row is ever wanted, this comment holds the URL.
--
-- ── ⚠️ THIS MAKES THE ROW A WEEKLY TASK, WHICH IT WAS NOT BEFORE ──
-- 114 established that /resources gets exactly ONE durable Game Photos row and
-- explicitly rejected a row per album, because albums accrue forever and turn
-- Forms & Links into a junk drawer. That rule is not broken here -- there is
-- still exactly one row -- but its destination is now a single game rather than
-- an index, so it goes stale the moment the next album exists. It joins the VYPE
-- broadcast links as a standing week-by-week update; see followups.md.
-- The permanent fix is an index doc for 2026-27 that the row can point at again.
--
-- ── ⚠️ TWO WARNINGS THAT CARRY FORWARD FROM 114 AND 131, UNCHANGED ──
-- 1. A Google Photos share link is PUBLIC TO ANYONE HOLDING IT, and these are
--    photos of minors. Jeremy's call, made for the pool party (114), again for
--    Meet the Mavs (131), and again here.
-- 2. ALBUM LINKS ROT SILENTLY. Nothing detects an unshared or deleted album; the
--    site just shows a dead link. Only a human revisiting it will notice.
--
-- Link verified before writing, per the standing procedure that catches a URL
-- pasted from the wrong week: HTTP 200 under a desktop UA, and og:title reads
-- "20260828 MHS Varsity Football at Bowie" -- the right season, the right game,
-- and the same YYYYMMDD naming the retired doc used for its own entries.
--
-- DB-ONLY, NO DEPLOY. /resources reads at request time.
--
-- Rollback: 185_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from resource_links
   where section = 'communications' and label = 'Game Photos'
     and url like 'https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0%';
  if n <> 1 then raise exception 'Game Photos row not found on the 2025-26 doc (found %)', n; end if;
end $$;

update resource_links
   set url = 'https://photos.google.com/share/AF1QipPF3TczLboM6HbLAFW-cgJ2dISqbpe_3SMqE5ZgkMAADhMfb9ol8ZaEy4jQKVd1bQ?key=aHNnSG9pQnh6QzhOczJRZ05LZ1gtS1hlMXlwYWJ3',
       description = 'Photos from the 2026 season, shared by McNeil Mavericks families. Currently: Varsity at Austin Bowie, Aug 28.',
       updated_at = now()
 where section = 'communications' and label = 'Game Photos';

do $$
declare n int;
begin
  select count(*) into n from resource_links
   where section = 'communications' and label = 'Game Photos'
     and url like 'https://photos.google.com/share/AF1QipPF3TczLboM6HbLAFW%'
     and description like '%Varsity at Austin Bowie, Aug 28.'
     and active;
  if n <> 1 then raise exception 'Game Photos row did not update'; end if;

  -- Still exactly one Game Photos row: 114's rule, restated as a guard.
  select count(*) into n from resource_links where label like 'Game Photos%';
  if n <> 1 then raise exception 'expected exactly 1 Game Photos row, found %', n; end if;

  -- The retired doc must not be left behind on some other row.
  select count(*) into n from resource_links
   where url like '%1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0%';
  if n <> 0 then raise exception 'the 2025-26 photo doc is still linked from % row(s)', n; end if;

  -- The sibling Event Photos row (114) is a different thing and is untouched.
  select count(*) into n from resource_links
   where label = 'Event Photos' and url = '/events?filter=past' and active;
  if n <> 1 then raise exception 'the Event Photos row was disturbed'; end if;
end $$;

commit;

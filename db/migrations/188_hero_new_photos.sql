-- 188_hero_new_photos.sql
--
-- Four new homepage hero photos from Jeremy, 2026-09-06, with the framing he
-- asked for. Replaces four of the six backgrounds; the mascot (hero-02, slide 2)
-- and the marching band (hero-01, slide 6) are untouched.
--
--   file replaced   slide   new object            anchor    was
--   hero-03.jpg     3       hero-dance.jpg        center    cheer team performing
--   hero-04.jpg     4       hero-cheer.jpg        center    cheerleaders on sideline
--   hero-05.jpg     5       hero-team2.jpg        bottom    player catching a TD
--   hero-06.jpg     1       hero-team.jpg         center    team running onto the field
--
-- ⚠️ "hero 6" WAS AMBIGUOUS AND WAS CONFIRMED, NOT ASSUMED. The FILE hero-06.jpg
-- is slide 1 (sort_order 1), while slide 6 is the file hero-01.jpg -- the numbers
-- have not lined up since the rows were seeded. Jeremy confirmed he meant the
-- file, which also makes it a like-for-like swap: hero-team.jpg IS a team
-- running onto the field. 🚫 The marching band photo therefore STAYS. If a
-- future request says "hero N", ask which of the two Ns it is before writing.
--
-- ── THE ANCHORS ARE JEREMY'S WORDS, NOT AESTHETIC JUDGEMENT ──
-- dance / cheer / team: "the same amount of the photo not seen at top and
-- bottom" -> 'center'.
-- team2: "I don't want to see the top of the picture, but all of the bottom" ->
-- 'bottom', which pins the image's bottom edge to the box's and crops downward
-- from the top. That is the intent exactly: the top of that frame is scoreboard
-- and dark stadium, the bottom is the team lined up on the grass.
--
-- ⚠️ ON A WIDE DESKTOP 'bottom' TRIMS MORE THAN IT LOOKS LIKE IT WILL. At
-- ~1728x1000 the hero box is about 2.24:1 against a 3:2 photo, so roughly a
-- third of the height goes -- enough to clip the top of the tallest helmets in
-- hero-team2.jpg. Flagged to Jeremy. It is what he asked for and it is trivially
-- reversible: one UPDATE to 'center'.
--
-- ── THE FILES WERE PREPARED, NOT UPLOADED RAW ──
-- Sources were 20-31 MB at up to 9504 px wide. `scripts/prep-hero-image.py`
-- (new, in the ops repo) produced 1920x1280 sRGB JPEGs at 581-744 KB, inside the
-- 658-915 KB band of the six already in the bucket. ⚠️ It also STRIPS ALL EXIF,
-- which matters here beyond hygiene: these are photographs of minors and camera
-- metadata routinely carries GPS. All four sources were already exactly 3:2, so
-- the centre-crop was a no-op (dance lost one pixel of width).
--
-- 🚫 NEW FILENAMES, NOT OVERWRITES OF hero-03..06. Supabase Storage serves
-- `cache-control: no-cache`, so Next falls back to `minimumCacheTTL` = 31 days
-- (set deliberately in next.config.ts) and replacing an object at a live path
-- can serve the OLD photo for a month with no way to invalidate. 158's rule,
-- same as 169's sponsor logo and the roster PDFs. The four retired objects stay
-- in the bucket, unreferenced, so the rollback has something to point back at.
-- ⚠️ A future replacement for hero-dance.jpg is hero-dance-r2.jpg, NOT a
-- re-upload of the same name.
--
-- ⚠️ REQUIRES MIGRATION 187 *AND* THE DEPLOY THAT READS `object_position`.
-- Applied against the old code every one of these renders top-anchored -- not
-- broken, but not what was asked for. Order: 187 -> deploy -> 188.
--
-- DB-ONLY. The homepage revalidates on its own; no deploy is needed for THIS
-- migration, only for the 187 column read.
--
-- Rollback: 188_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n
    from information_schema.columns
   where table_schema = 'public' and table_name = 'hero_background_images'
     and column_name = 'object_position';
  if n <> 1 then raise exception 'migration 187 has not been applied'; end if;

  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-03.jpg','hero/hero-04.jpg','hero/hero-05.jpg','hero/hero-06.jpg');
  if n <> 4 then raise exception 'expected the 4 outgoing hero rows, found % (already applied?)', n; end if;

  select count(*) into n from hero_background_images where object_position <> 'top';
  if n <> 0 then raise exception 'a hero row is already non-top; 188 expects 187 state'; end if;
end $$;

update hero_background_images
   set storage_path = 'hero/hero-dance.jpg',
       alt_text = 'McNeil drill team performing on the field during a football game',
       object_position = 'center',
       updated_at = now()
 where storage_path = 'hero/hero-03.jpg';

update hero_background_images
   set storage_path = 'hero/hero-cheer.jpg',
       alt_text = 'McNeil cheerleaders raising pom-poms on the sideline during a football game',
       object_position = 'center',
       updated_at = now()
 where storage_path = 'hero/hero-04.jpg';

update hero_background_images
   set storage_path = 'hero/hero-team2.jpg',
       alt_text = 'McNeil Mavericks football team lined up arm in arm along the sideline',
       object_position = 'bottom',
       updated_at = now()
 where storage_path = 'hero/hero-05.jpg';

-- hero-06 is the row whose identity had to be confirmed with Jeremy (see the
-- header): the FILE hero-06.jpg, which is slide 1, not slide 6.
update hero_background_images
   set storage_path = 'hero/hero-team.jpg',
       alt_text = 'McNeil Mavericks football team running onto the field carrying the American flag',
       object_position = 'center',
       updated_at = now()
 where storage_path = 'hero/hero-06.jpg';

do $$
declare n int;
begin
  select count(*) into n from hero_background_images;
  if n <> 6 then raise exception 'expected 6 hero rows, found %', n; end if;

  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-dance.jpg','hero/hero-cheer.jpg',
                          'hero/hero-team2.jpg','hero/hero-team.jpg')
     and active;
  if n <> 4 then raise exception 'expected 4 new active hero rows, found %', n; end if;

  -- None of the retired paths may still be referenced.
  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-03.jpg','hero/hero-04.jpg',
                          'hero/hero-05.jpg','hero/hero-06.jpg');
  if n <> 0 then raise exception '% retired hero path(s) still referenced', n; end if;

  -- The two survivors are untouched and still anchored top.
  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-01.jpg','hero/hero-02.jpg')
     and object_position = 'top' and active;
  if n <> 2 then raise exception 'the mascot / marching band rows were disturbed'; end if;

  -- Anchors are exactly what Jeremy asked for: three centred, one bottom.
  select count(*) into n from hero_background_images where object_position = 'center';
  if n <> 3 then raise exception 'expected 3 centred hero rows, found %', n; end if;

  select count(*) into n from hero_background_images
   where object_position = 'bottom' and storage_path = 'hero/hero-team2.jpg';
  if n <> 1 then raise exception 'team2 is not the bottom-anchored row'; end if;

  -- Slide order is untouched: sort_order still 1..6, one row each.
  select count(distinct sort_order) into n from hero_background_images;
  if n <> 6 then raise exception 'sort_order collided (% distinct)', n; end if;
end $$;

commit;

-- 187_hero_object_position.sql
--
-- Adds `object_position` to `hero_background_images` so each hero photo can say
-- where it anchors when the browser crops it. Jeremy 2026-09-06, sending four
-- replacement photos: two should sit centred, one should show all of its bottom
-- and lose its top.
--
-- ── WHY THIS CANNOT BE BAKED INTO THE IMAGE FILE ──
-- The hero is `min-h-[55vh] md:min-h-[77vh]` at full width, so ITS ASPECT RATIO
-- IS THE VIEWPORT'S, and it is never the image's. On a 1728x1000 desktop the
-- box is ~2.24:1 and `object-cover` throws away a third of a 3:2 photo's height;
-- on a phone the box is TALLER than 3:2 and it crops the sides instead, showing
-- the full height. So "how much is cut off the top" is a different number on
-- every device, and no crop applied by `prep-hero-image.py` can be right at all
-- of them. Only the browser knows, which makes this a CSS `object-position`
-- decision, stored per row.
--
-- ── DEFAULT 'top' IS NOT A NEUTRAL CHOICE, IT PRESERVES THE STATUS QUO ──
-- `HeroCarousel` has hardcoded `object-cover object-top` on every background
-- since the carousel was built. Defaulting the column to 'top' and backfilling
-- every existing row with it means this migration changes NOTHING on screen --
-- which is the point. It is safe to apply before the code that reads it ships.
--
-- ⚠️ APPLY THIS BEFORE DEPLOYING THE CODE THAT READS THE COLUMN, never after.
-- Same ordering rule as 056/057/058: the column exists first, then the code that
-- selects it. `loadHeroCarouselData` does `select("*")`, so a deploy that lands
-- against a DB without this column would hand `undefined` to the class lookup.
--
-- The CHECK constraint is deliberately a closed set of three rather than free
-- text. `HeroCarousel` maps the value to a literal Tailwind class, and Tailwind
-- v4 only emits classes it can SEE as strings in the source -- an arbitrary
-- value like 'center 30%' would store fine, pass through the component, and
-- then not exist as CSS. A silent no-op, on the homepage. If a fourth anchor is
-- ever wanted, it needs a new literal in the component AND a new value here.
--
-- DB-ONLY. Safe to apply on its own; renders identically until the code ships.
--
-- Rollback: 187_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n
    from information_schema.columns
   where table_schema = 'public' and table_name = 'hero_background_images'
     and column_name = 'object_position';
  if n <> 0 then raise exception 'hero_background_images.object_position already exists'; end if;

  select count(*) into n from hero_background_images;
  if n <> 6 then raise exception 'expected 6 hero rows, found %', n; end if;
end $$;

alter table hero_background_images
  add column object_position text not null default 'top';

alter table hero_background_images
  add constraint hero_background_images_object_position_check
  check (object_position in ('top', 'center', 'bottom'));

do $$
declare n int;
begin
  -- Every existing row must read 'top', i.e. exactly what the hardcoded class
  -- did. If this is not 6, the default did not take and the homepage is about
  -- to reframe six photos nobody asked to reframe.
  select count(*) into n from hero_background_images where object_position = 'top';
  if n <> 6 then raise exception 'expected 6 rows anchored top, found %', n; end if;
end $$;

commit;

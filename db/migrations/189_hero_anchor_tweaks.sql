-- 189_hero_anchor_tweaks.sql
--
-- Two crop anchors moved to 'center', both on Jeremy's say-so after seeing 188
-- live, 2026-09-06:
--
--   hero/hero-team2.jpg   bottom -> center   "bottom looks odd"
--   hero/hero-02.jpg      top    -> center   (the mascot, slide 2)
--
-- ── team2 IS A REVERSAL OF AN EXPLICIT REQUEST, AND THAT IS FINE ──
-- 188 set 'bottom' because Jeremy asked for "all of the bottom" and no top. Seen
-- on the page he preferred it centred. 🚫 Do not "restore" 'bottom' on the
-- strength of 188's comment -- this entry supersedes it. The photo is a team
-- lined up along a sideline, so it is mostly one horizontal band either way;
-- centring keeps a little sky and a little grass instead of pinning the grass.
--
-- hero-02 is the FIRST photo to move off 'top' that was not part of the
-- four-photo swap. It has been top-anchored since the carousel was built, which
-- was never a decision -- 'top' was hardcoded for every background until 187,
-- so it is simply what everything inherited.
--
-- ⚠️ hero-01.jpg (marching band, slide 6) IS DELIBERATELY LEFT ON 'top'. Jeremy
-- named team2 and hero-02 specifically. It is the last row still carrying the
-- pre-187 inherited anchor, so if someone later wonders whether 'top' there is
-- intentional: it is untested, not chosen. Worth a look, not worth assuming.
--
-- DB-ONLY, NO DEPLOY. The homepage revalidates on its own and the code that
-- reads `object_position` shipped with 188.
--
-- Rollback: 189_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from hero_background_images
   where storage_path = 'hero/hero-team2.jpg' and object_position = 'bottom';
  if n <> 1 then raise exception 'team2 is not bottom-anchored (already applied?)'; end if;

  select count(*) into n from hero_background_images
   where storage_path = 'hero/hero-02.jpg' and object_position = 'top';
  if n <> 1 then raise exception 'hero-02 is not top-anchored (already applied?)'; end if;
end $$;

update hero_background_images
   set object_position = 'center', updated_at = now()
 where storage_path in ('hero/hero-team2.jpg', 'hero/hero-02.jpg');

do $$
declare n int;
begin
  select count(*) into n from hero_background_images where object_position = 'center';
  if n <> 5 then raise exception 'expected 5 centred hero rows, found %', n; end if;

  select count(*) into n from hero_background_images where object_position = 'bottom';
  if n <> 0 then raise exception 'a hero row is still bottom-anchored'; end if;

  -- The marching band row is the only one left on 'top', on purpose.
  select count(*) into n from hero_background_images
   where object_position = 'top' and storage_path = 'hero/hero-01.jpg';
  if n <> 1 then raise exception 'hero-01 should be the sole remaining top-anchored row'; end if;

  select count(*) into n from hero_background_images;
  if n <> 6 then raise exception 'expected 6 hero rows, found %', n; end if;
end $$;

commit;

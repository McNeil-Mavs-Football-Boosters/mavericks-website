-- 187_rollback.sql
--
-- Drops `object_position` and its constraint.
--
-- ⚠️ ROLL THE CODE BACK FIRST. `HeroCarousel` reads this column once the deploy
-- lands; dropping it under the running code leaves every background falling back
-- to the component's default anchor. That fallback is 'top', so the page still
-- renders -- but 188's centred and bottom-anchored photos would silently revert
-- to top-anchored, which is the framing Jeremy explicitly asked to change.

begin;

do $$
declare n int;
begin
  select count(*) into n from hero_background_images where object_position <> 'top';
  if n <> 0 then
    raise exception '% hero row(s) rely on a non-top anchor; roll back 188 first', n;
  end if;
end $$;

alter table hero_background_images
  drop constraint if exists hero_background_images_object_position_check;

alter table hero_background_images
  drop column object_position;

commit;

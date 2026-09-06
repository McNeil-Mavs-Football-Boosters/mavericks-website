-- 185_rollback.sql
--
-- Points the Game Photos row back at djohnsonjr's "2025-2026 McNeil Football
-- Photos" doc, with its original description. Note that doing so restores a link
-- that contains nothing from the 2026-27 season.

begin;

do $$
declare n int;
begin
  select count(*) into n from resource_links
   where section = 'communications' and label = 'Game Photos'
     and url like 'https://photos.google.com/share/AF1QipPF3TczLboM6HbLAFW%';
  if n <> 1 then raise exception 'Game Photos row is not on the Bowie album (not 185 to roll back?)'; end if;
end $$;

update resource_links
   set url = 'https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0/edit?tab=t.0#heading=h.gf4l39u0yuz6',
       description = 'Game photos shared by McNeil Mavericks families.',
       updated_at = now()
 where section = 'communications' and label = 'Game Photos';

commit;

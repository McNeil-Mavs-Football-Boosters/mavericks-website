-- 189_rollback.sql
--
-- Restores 188's anchors: team2 back to 'bottom', the mascot back to 'top'.

begin;

do $$
declare n int;
begin
  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-team2.jpg','hero/hero-02.jpg')
     and object_position = 'center';
  if n <> 2 then raise exception 'the two 189 rows are not both centred (not 189 to roll back?)'; end if;
end $$;

update hero_background_images
   set object_position = 'bottom', updated_at = now()
 where storage_path = 'hero/hero-team2.jpg';

update hero_background_images
   set object_position = 'top', updated_at = now()
 where storage_path = 'hero/hero-02.jpg';

commit;

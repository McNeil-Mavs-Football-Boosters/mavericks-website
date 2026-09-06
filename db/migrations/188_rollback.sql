-- 188_rollback.sql
--
-- Points the four hero rows back at hero-03/04/05/06.jpg with their original alt
-- text, and returns every row to the 'top' anchor that predated 187.
--
-- The four retired objects were never deleted (158's rule: retired revisions
-- stay in the bucket, unreferenced), so this needs no re-upload.
--
-- ⚠️ The four NEW objects are left in the bucket too. Do not delete them on a
-- rollback -- if this is being rolled back to fix framing rather than to reject
-- the photos, they will be wanted again in minutes, and re-uploading under the
-- same name is the 31-day stale-cache trap.

begin;

do $$
declare n int;
begin
  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-dance.jpg','hero/hero-cheer.jpg',
                          'hero/hero-team2.jpg','hero/hero-team.jpg');
  if n <> 4 then raise exception 'the 4 new hero rows are not present (not 188 to roll back?)'; end if;
end $$;

update hero_background_images
   set storage_path = 'hero/hero-03.jpg',
       alt_text = 'McNeil cheer team performing during a football game',
       object_position = 'top', updated_at = now()
 where storage_path = 'hero/hero-dance.jpg';

update hero_background_images
   set storage_path = 'hero/hero-04.jpg',
       alt_text = 'McNeil cheerleaders on the sideline during a football game',
       object_position = 'top', updated_at = now()
 where storage_path = 'hero/hero-cheer.jpg';

update hero_background_images
   set storage_path = 'hero/hero-05.jpg',
       alt_text = 'McNeil Mavericks player catching a touchdown pass',
       object_position = 'top', updated_at = now()
 where storage_path = 'hero/hero-team2.jpg';

update hero_background_images
   set storage_path = 'hero/hero-06.jpg',
       alt_text = 'McNeil Mavericks football team running onto the field',
       object_position = 'top', updated_at = now()
 where storage_path = 'hero/hero-team.jpg';

do $$
declare n int;
begin
  select count(*) into n from hero_background_images where object_position = 'top';
  if n <> 6 then raise exception 'expected all 6 rows anchored top after rollback, found %', n; end if;

  select count(*) into n from hero_background_images
   where storage_path in ('hero/hero-01.jpg','hero/hero-02.jpg','hero/hero-03.jpg',
                          'hero/hero-04.jpg','hero/hero-05.jpg','hero/hero-06.jpg');
  if n <> 6 then raise exception 'hero paths not fully restored (%)', n; end if;
end $$;

commit;

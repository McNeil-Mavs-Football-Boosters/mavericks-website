-- 213_coach_photos_photoday_2026.sql
--
-- New headshots for the whole staff from the 2026 photo-day portraits, and a new
-- coach row for Raleigh Texada. Jeremy 2026-09-22: "names are in the file name
-- now. Raleigh Texada is the DB Coach. Can you update the pics on the website
-- please? crop as needed."
--
-- Crops: MavericksWebsite/coach_photos/crop_photoday_2026.py, sources pinned in
-- coach_photos/sources/photoday-2026/ (never read from ~/Downloads, see
-- crop_faces.py). 600x600 head-and-shoulders, same as the existing headshots.
-- Haar failed on two and they use pinned hand boxes (Debose, Gardner). All 12
-- reviewed on a contact sheet before upload.
--
-- ⚠️ NEW OBJECT NAMES (Coach<Name>2026.jpg), not overwrites: next.config.ts
-- caches images 31 days, so overwriting a path could keep serving the old face.
-- The previous objects stay in the bucket; 213_rollback.sql points back at them.
-- ⚠️ Doyle had NO photo before (photo_url NULL, horseshoe fallback). Now he does.
--
-- ⚠️ TEXADA AND JONES ARE BOTH "Defensive Backs Coach" after this. Jeremy said
-- Texada is the DB coach and said nothing about Jones, so Jones is untouched.
-- If Jones has moved to another position, it is a one-line role update.
-- Texada sorts right after Jones (36). No teaching role, email or phone known.
--
-- DB-ONLY, NO DEPLOY. Rollback: 213_rollback.sql
begin;
do $$
declare n int;
begin
  select count(*) into n from coaches where year = '2026-27' and name = 'Raleigh Texada';
  if n <> 0 then raise exception 'Texada already exists'; end if;
  select count(*) into n from coaches where year = '2026-27' and active and photo_url like '%2026.jpg';
  if n <> 0 then raise exception 'photo-day photos already applied (%)', n; end if;
end $$;
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachGardner2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Jerry Gardner';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachGillis2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Alexander Gillis';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachHale2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Michael Hale';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachMatthews2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Barrett Matthews';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWallin2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Douglas Wallin';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachDebose2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Reginal Debose';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachEdwards2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Nick Edwards';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWard2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Justin Ward';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachUmberger2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Thomas Umberger';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachDoyle2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Ryan Doyle';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachJones2026.jpg', updated_at = now() where year = '2026-27' and active and name = 'Devonte Jones';
insert into coaches (year, name, role, role_category, photo_url, sort_order, active)
values ('2026-27', 'Raleigh Texada', 'Defensive Backs Coach', 'position_coach', 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachTexada2026.jpg', 36, true);
do $$
declare n int;
begin
  select count(*) into n from coaches where year = '2026-27' and active and photo_url like 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/Coach%2026.jpg';
  if n <> 12 then raise exception 'expected 12 active coaches on 2026 photos, found %', n; end if;
  select count(*) into n from coaches where year = '2026-27' and active and photo_url is null;
  if n <> 0 then raise exception '% active coaches still have no photo', n; end if;
end $$;
commit;

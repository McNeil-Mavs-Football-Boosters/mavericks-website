-- 252_trainer_maggie_florez_cook.sql
--
-- Head athletic trainer on /coaches (Jeremy 2026-10-20, bio + headshot supplied).
-- Spelling "Florez-Cook" per Jeremy and the RRISD athletics article; the coaches'
-- roster sheet (and so the Print View PDFs) says "Flores-Cook".
-- Bio rewritten to third person (Jeremy's text switched to "my free time");
-- facts unchanged. No email: not verified in the RRISD directory, so none guessed.
-- Photo: coach_photos/crop_photoday_2026.py from sources/photoday-2026/florez-cook.png,
-- uploaded coach-photos/CoachFlorezCook2026.jpg, sha256 round trip OK.
-- First row in the 'trainer' category, so the "Trainers" section appears on /coaches.
--
-- DB-ONLY, NO DEPLOY. Rollback: 252_rollback.sql

begin;

insert into coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active, bio)
select '2026-27', 'Maggie Florez-Cook', 'Head Athletic Trainer', 'trainer', null, null,
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachFlorezCook2026.jpg',
       50, true,
       'Maggie Florez-Cook, "Miss Maggie" to the athletes, is the Mavericks'' head athletic trainer and has been at McNeil since July 2012. Before McNeil she spent three years at Ozen High School in Beaumont. She earned a bachelor''s degree in Athletic Training and a master''s degree in Exercise and Sports Science in Research from the University of Mary Hardin-Baylor. Miss Maggie is a proud wife to Burnie and mom to Liam, and in her free time she enjoys spending time with her family and attending her son''s sporting events.'
where not exists (select 1 from coaches where year = '2026-27' and name in ('Maggie Florez-Cook', 'Maggie Flores-Cook'));

do $$
declare n int;
begin
  select count(*) into n from coaches where year = '2026-27' and active and role_category = 'trainer';
  if n <> 1 then raise exception 'expected 1 active trainer, found %', n; end if;
end $$;

commit;

-- 214_coach_contacts_from_mcneil_directory.sql
--
-- Coach emails and teaching subjects from the McNeil staff directory
-- (mcneil.roundrockisd.org/o/mcneil/staff), searched by last name 2026-09-22 at
-- Jeremy's request ("pull coaches' info ... then update the website"). Read with
-- headless Chromium; the directory lists department, title and email. It lists
-- NO phone numbers for any coach, so `phone` is not touched.
--
--   Coach            directory department            email (as the directory writes it)
--   Gardner          Coordinator, Campus ATH CY      jerry_gardner@          (already set)
--   Gillis           Athletics                       alexander_gillis@       NEW email; no teaching subject
--   Hale             Physical Education & Athletics  Michael_Hale@           (already set)
--   Matthews         CTE                             barrett_matthews@       NEW email + "CTE Teacher"
--   Wallin           Social Studies & Athletics      Douglas_Wallin@         (already set)
--   Debose           CTE                             reginal_debose@         ⚠️ subject CHANGED
--   Edwards          Social Studies & Athletics      nicholas_edwards@       NEW email + "Social Studies Teacher"
--   Ward             Physical Education & Athletics  Justin_Ward@            (already set)
--   Umberger         Physical Education & Athletics  thomas_umberger@        NEW email + "Physical Education Teacher"
--   Doyle            Physical Education & Athletics  Ryan_Doyle@             (already set)
--   Jones            Special Education               devonte_jones@          (already set)
--   Texada           Physical Education & Athletics  raleigh_texada@         NEW email + "Physical Education Teacher"
--
-- ⚠️ DEBOSE: the site said "Special Education Teacher" (062); the directory now
-- lists him under CTE. The directory is the school's current record, so it wins.
-- ⚠️ EDWARDS is "Nicholas Edwards" in the directory and "Nick Edwards" on the
-- site; same Social Studies & Athletics coach, display name left as Nick.
-- ⚠️ GILLIS's department is plain "Athletics", which names no class, so no
-- teaching_role line is invented for him. Gardner's directory title matches the
-- "Athletic Coordinator" already in his football role; no teaching line either.
-- Subjects are phrased like the existing rows ("<Subject> Teacher").
--
-- DB-ONLY, NO DEPLOY. Rollback: 214_rollback.sql
begin;
do $$
declare n int;
begin
  select count(*) into n from coaches where year = '2026-27' and active and email is null
     and name in ('Alexander Gillis','Barrett Matthews','Nick Edwards','Thomas Umberger','Raleigh Texada');
  if n <> 5 then raise exception 'expected 5 coaches without email, found % (already applied?)', n; end if;
  select count(*) into n from coaches where year = '2026-27' and name = 'Reginal Debose' and teaching_role = 'Special Education Teacher';
  if n <> 1 then raise exception 'Debose teaching_role not as expected'; end if;
end $$;

update coaches set email = 'alexander_gillis@roundrockisd.org', updated_at = now() where year = '2026-27' and active and name = 'Alexander Gillis';
update coaches set email = 'barrett_matthews@roundrockisd.org', teaching_role = 'CTE Teacher', updated_at = now() where year = '2026-27' and active and name = 'Barrett Matthews';
update coaches set email = 'nicholas_edwards@roundrockisd.org', teaching_role = 'Social Studies Teacher', updated_at = now() where year = '2026-27' and active and name = 'Nick Edwards';
update coaches set email = 'thomas_umberger@roundrockisd.org', teaching_role = 'Physical Education Teacher', updated_at = now() where year = '2026-27' and active and name = 'Thomas Umberger';
update coaches set email = 'raleigh_texada@roundrockisd.org', teaching_role = 'Physical Education Teacher', updated_at = now() where year = '2026-27' and active and name = 'Raleigh Texada';
update coaches set teaching_role = 'CTE Teacher', updated_at = now() where year = '2026-27' and active and name = 'Reginal Debose';

do $$
declare n int;
begin
  select count(*) into n from coaches where year = '2026-27' and active and email like '%@roundrockisd.org';
  if n <> 12 then raise exception 'expected all 12 active coaches with an RRISD email, found %', n; end if;
  select count(*) into n from coaches where year = '2026-27' and active and phone is not null;
  if n <> 0 then raise exception 'a phone number appeared (%); none should have been touched', n; end if;
end $$;
commit;

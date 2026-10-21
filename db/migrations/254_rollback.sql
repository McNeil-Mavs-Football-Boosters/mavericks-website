-- 254_rollback.sql -- Print View back to varsity r11 / jv r4 (still in the bucket); Hale back to Michael.
begin;
update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r11.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r4.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;
update coaches set name = 'Michael Hale', updated_at = now()
 where year = '2026-27' and name = 'Jake Hale';
commit;

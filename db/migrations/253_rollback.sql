-- 253_rollback.sql -- Print View back to varsity r10 / jv r3 (both still in the bucket).
begin;
update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r10.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
update rosters set pdf_storage_path = 'documents/rosters/jv-2026-r3.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;
commit;

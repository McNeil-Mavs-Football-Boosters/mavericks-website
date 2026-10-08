-- 233_rollback.sql -- Deshay back to Sr., PDF back to r8.
begin;
update players p set grade = 'Sr.', updated_at = now() from rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and p.jersey_number = '32' and p.last_name = 'Deshay';
update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r8.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;
commit;

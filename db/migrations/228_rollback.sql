-- 228_rollback.sql -- restores the two names as the coaches' export had them, PDF back to r5.
begin;
update players pl set last_name = 'Southernland', updated_at = now() from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '30' and pl.last_name = 'Sutherland';
update players pl set first_name = 'Amery A.', updated_at = now() from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '84/80' and pl.first_name = 'Amery';
update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity';
commit;

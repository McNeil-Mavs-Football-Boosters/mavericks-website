-- 230_rollback.sql -- restores #90 as the coaches' export had it, PDF back to r6.
begin;
update players pl set last_name = 'Galaza', updated_at = now() from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '90' and pl.last_name = 'Galarza';
update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r6.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity';
commit;

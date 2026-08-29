-- 171_rollback.sql — restores Askins to '9/10', El Anssari to '29', the
-- pre-171 sort order, and the r2 PDF.
--
-- varsity-2026-r3.pdf stays in the bucket (171 uploaded a new object rather
-- than overwriting r2, so r2 is untouched and this just re-points at it).
-- The coaches' workbook on Jeremy's disk is NOT reverted by this file; if you
-- roll back for real, regenerate the PDF from a restored workbook too.

begin;

update players p set jersey_number = '9/10', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='varsity'
   and p.first_name='Ford' and p.last_name='Askins';

update players p set jersey_number = '29', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='varsity'
   and p.first_name='Aymane' and p.last_name='El Anssari';

with ranked as (
  select p.id,
         row_number() over (
           order by (regexp_match(p.jersey_number, '^\d+'))[1]::int, p.last_name
         ) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='varsity'
     and r.team_designation is null and p.active
)
update players p set sort_order = ranked.rn, updated_at = now()
  from ranked where p.id = ranked.id and p.sort_order is distinct from ranked.rn;

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r2.pdf',
                   updated_at = now()
 where year='2026-27' and team_level='varsity' and team_designation is null;

commit;

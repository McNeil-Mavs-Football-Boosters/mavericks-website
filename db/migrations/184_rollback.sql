-- 184_rollback.sql
--
-- Returns varsity #67 Aiden Ross to a null position, i.e. the state 183 left him
-- in, where /roster/varsity renders an em-dash. The JV row is not touched.
--
-- ⚠️ The workbook and the print PDF also carry OL. Rolling this back alone puts
-- the page and the printed roster back into disagreement -- the 176 bug. Either
-- roll 186 back too and regenerate the PDF from a corrected workbook, or accept
-- that the wall poster says OL and the site does not.

begin;

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.jersey_number = '67' and p.position = 'OL';
  if n <> 1 then raise exception 'varsity #67 does not read OL (not 184 to roll back?)'; end if;
end $$;

update players p
   set position = null, updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross';

commit;

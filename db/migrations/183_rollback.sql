-- 183_rollback.sql
--
-- Removes #67 Aiden Ross from the varsity roster and re-densifies sort_order
-- back to 1..45 by the same leading-number rule 183 used. The JV row is not
-- touched -- 183 did not create it and must not delete it.
--
-- ⚠️ If 186 has been applied, roll that back FIRST: leaving the roster row
-- pointing at varsity-2026-r4.pdf while the DB has 45 players puts the printed
-- roster and the page back into disagreement, which is the 176 bug.

begin;

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross';
  if n <> 1 then raise exception 'varsity Aiden Ross row not found (not 183 to roll back?)'; end if;

  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf';
  if n <> 0 then raise exception 'migration 186 is still applied; roll it back first'; end if;
end $$;

delete from players p
 using rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross';

with ordered as (
  select p.id,
         row_number() over (order by split_part(p.jersey_number, '/', 1)::int) as rn
    from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
)
update players p
   set sort_order = o.rn, updated_at = now()
  from ordered o
 where o.id = p.id and p.sort_order is distinct from o.rn;

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null;
  if n <> 45 then raise exception 'expected 45 varsity players after rollback, found %', n; end if;
end $$;

commit;

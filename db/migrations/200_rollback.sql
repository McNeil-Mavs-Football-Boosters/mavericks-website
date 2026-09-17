-- 200_rollback.sql
--
-- Reverses the four roster changes and repoints Print View at the original
-- freshman-2026.pdf, which was left in the bucket for exactly this. Roll back
-- only if the coaches' revised PDF itself was wrong.

begin;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year='2026-27' and team_level='freshman' and team_designation='Green'
     and pdf_storage_path = 'documents/rosters/freshman-2026-r2.pdf';
  if rid is null then raise exception 'freshman Green is not on r2 (not 200 to roll back?)'; end if;
  select count(*) into n from players where roster_id = rid;
  if n <> 50 then raise exception 'expected 50 players, found %', n; end if;
end $$;

delete from players p using rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number='19' and p.first_name='Khalil' and p.last_name='Miller';

update players p set jersey_number='30', updated_at=now() from rosters r
 where r.id=p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number='35' and p.first_name='Quinten' and p.last_name='Spurlock';

update players p set jersey_number='SWAP', updated_at=now() from rosters r
 where r.id=p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number='56' and p.first_name='Adam' and p.last_name='Zayad';
update players p set jersey_number='56', updated_at=now() from rosters r
 where r.id=p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number='74' and p.first_name='Andy' and p.last_name='Fernandez';
update players p set jersey_number='74', updated_at=now() from rosters r
 where r.id=p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number='SWAP';

with ranked as (
  select p.id, row_number() over (order by (p.jersey_number)::int) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
)
update players p set sort_order = ranked.rn, updated_at = now()
  from ranked where ranked.id = p.id and p.sort_order is distinct from ranked.rn;

update rosters
   set pdf_storage_path = 'documents/rosters/freshman-2026.pdf',
       source_note = 'Freshman roster provided by the McNeil coaching staff, received 2026-08-26',
       updated_at = now()
 where year='2026-27' and team_level='freshman' and team_designation='Green';

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters where year='2026-27' and team_level='freshman' and team_designation='Green';
  select count(*) into n from players where roster_id = rid;
  if n <> 49 then raise exception 'rollback left % players, expected 49', n; end if;
  if (select count(*) from players where roster_id=rid and jersey_number in ('19','35','SWAP')) <> 0 then
    raise exception 'rollback left a #19, #35 or placeholder'; end if;
end $$;

commit;

-- 203_rollback.sql
--
-- Puts the two Wednesday Sep 23 Lake Travis rows (JV, freshman Green) back to
-- 'scheduled' at their stored school-export times. Nothing else was touched.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and result_status = 'tbd' and game_date::date = date '2026-09-23';
  if n <> 2 then raise exception 'expected 2 tbd rows on Sep 23, found % (203 not applied?)', n; end if;
end $$;

update games
   set result_status = 'scheduled', updated_at = now()
 where year = '2026-27' and result_status = 'tbd' and game_date::date = date '2026-09-23'
   and opponent = 'Lake Travis High School'
   and ((team_level = 'jv') or (team_level = 'freshman' and team_designation = 'Green'));

do $$
declare n int;
begin
  select count(*) into n from games where year = '2026-27' and result_status = 'tbd';
  if n <> 0 then raise exception '% tbd rows remain', n; end if;
end $$;

commit;

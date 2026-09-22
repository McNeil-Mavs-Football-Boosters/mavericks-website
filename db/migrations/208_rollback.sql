-- 208_rollback.sql -- back to Coach's shorthand name everywhere.
begin;
update venues set name = 'Lake Travis Track Stadium', updated_at = now() where name = 'Cavalier Track and Field Stadium';
update games set location = 'Lake Travis Track Stadium', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and location = 'Cavalier Track and Field Stadium';
update practice_schedules
   set body = replace(body, 'at Cavalier Track and Field Stadium (Lake Travis)', 'at Lake Travis Track Stadium'), updated_at = now()
 where year = '2026-27' and body like '%at Cavalier Track and Field Stadium (Lake Travis)%';
commit;

-- 198_rollback.sql
--
-- Removes the two Week 7 broadcast links from the varsity Vista Ridge game
-- (Sep 18). Deletes by URL on that game only; every other row is untouched.

begin;

delete from game_broadcasts gb
 using games g
 where g.id = gb.game_id
   and g.year = '2026-27'
   and g.team_level = 'varsity'
   and g.team_designation is null
   and g.game_date >= timestamptz '2026-09-18 00:00 America/Chicago'
   and g.game_date <  timestamptz '2026-09-19 00:00 America/Chicago'
   and g.opponent = 'Vista Ridge High School'
   and gb.url in ('https://youtube.com/live/bu2KuoBMs_0',
                  'https://www.vype.com/7pm-football-mcneil-vs-vista-ridge-2677859018');

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 6 then raise exception 'rollback left % varsity broadcast rows, expected 6', n; end if;
end $$;

commit;

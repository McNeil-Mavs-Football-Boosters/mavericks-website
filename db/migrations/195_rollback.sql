-- 195_rollback.sql
--
-- Removes the two Week 6 broadcast links from the varsity Rouse game (Sep 11).
-- Deletes by URL on that game only, so the Bowie and Lake Belton rows and the
-- legacy iHSFan row are untouched.

begin;

delete from game_broadcasts gb
 using games g
 where g.id = gb.game_id
   and g.year = '2026-27'
   and g.team_level = 'varsity'
   and g.team_designation is null
   and g.game_date >= timestamptz '2026-09-11 00:00 America/Chicago'
   and g.game_date <  timestamptz '2026-09-12 00:00 America/Chicago'
   and g.opponent = 'Rouse High School'
   and gb.url in ('https://youtube.com/live/NLfl3zeIPK4',
                  'https://www.vype.com/7pm-football-mcneil-vs-rouse');

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 4 then raise exception 'rollback left % varsity broadcast rows, expected 4', n; end if;
end $$;

commit;

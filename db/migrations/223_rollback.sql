-- 223_rollback.sql
--
-- Removes the two Week 9 (Cedar Ridge, Oct 2) broadcast rows. The game row
-- and every other week's links are untouched.

begin;

delete from game_broadcasts
 where url in ('https://youtube.com/live/hQwJ091W1A0',
               'https://www.vype.com/7pm-football-cedar-ridge-vs-mcneil-2677949441');

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts
   where url in ('https://youtube.com/live/hQwJ091W1A0',
                 'https://www.vype.com/7pm-football-cedar-ridge-vs-mcneil-2677949441');
  if n <> 0 then raise exception '% Cedar Ridge broadcast row(s) remain', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 10 then raise exception 'expected 10 varsity broadcast rows after rollback, found %', n; end if;
end $$;

commit;

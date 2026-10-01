-- 216_rollback.sql
--
-- Removes the two Week 8 (Lake Travis, Sep 24) broadcast rows. The game row
-- and every other week's links are untouched.

begin;

delete from game_broadcasts
 where url in ('https://youtube.com/live/uMgcaGseSxU',
               'https://www.vype.com/7pm-football-mcneil-vs-lake-travis');

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts
   where url in ('https://youtube.com/live/uMgcaGseSxU',
                 'https://www.vype.com/7pm-football-mcneil-vs-lake-travis');
  if n <> 0 then raise exception '% Lake Travis broadcast row(s) remain', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 8 then raise exception 'expected 8 varsity broadcast rows after rollback, found %', n; end if;
end $$;

commit;

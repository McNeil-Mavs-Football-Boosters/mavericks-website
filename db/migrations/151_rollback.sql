-- 151_rollback.sql — puts Senior Night back on the Sept 4 Lake Belton game.
--
-- Mirrors the forward migration's guards so a partial or already-rolled-back
-- state fails loudly instead of leaving the season with two Senior Nights or
-- none.

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09';
  if n <> 1 then
    raise exception 'Senior Night is not on 2026-10-09; nothing to roll back (matched % rows)', n;
  end if;
end $$;

update games
set notes = null
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-10-09'
  and notes = 'Senior Night';

update games
set notes = 'Senior Night'
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
  and opponent = 'Lake Belton High School'
  and notes is null;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night'
     and (game_date at time zone 'America/Chicago')::date = '2026-09-04';
  if n <> 1 then
    raise exception 'rollback did not restore Senior Night to 2026-09-04 (matched % rows)', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'expected exactly 1 Senior Night row after rollback, found %', n;
  end if;
end $$;

commit;

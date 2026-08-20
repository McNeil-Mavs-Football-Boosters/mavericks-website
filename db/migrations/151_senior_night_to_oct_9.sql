-- 151_senior_night_to_oct_9.sql
--
-- Senior Night moves off the Sept 4 home opener (Lake Belton) and onto the
-- Oct 9 home game vs Stony Point. Jeremy 2026-08-19.
--
-- It lands three weeks before Homecoming (Oct 23, migration 057) rather than on
-- top of it, which is the point: those are the only two occasion markers the
-- season carries and both render in the game title, so sharing a night would
-- have put "(Homecoming) (Senior Night)" on one row and given the seniors the
-- smaller half of the evening.
--
-- `notes` is doing double duty in this table — it holds the literal string
-- 'Scrimmage', which `gameTitle()` splices into the MIDDLE of the title, and
-- occasion markers like Homecoming / Senior Night, which it appends in parens.
-- This migration only ever touches the occasion kind. Do not let a 'Scrimmage'
-- row acquire an occasion marker: the title builder handles one or the other,
-- not both, and the Aug 13/Aug 20 scrimmages are the rows at risk.
--
-- DB-ONLY, NO DEPLOY. /events, /schedule/games/* and the month view all read at
-- request time, so the title changes as soon as this commits. ⚠️ /events.ics is
-- CDN-cached for an hour — verify the feed with a cache-buster (`?cb=1`) or you
-- will read a stale title and think this failed.
--
-- Oct 9 is NOT the last home game (Oct 23 vs Round Rock is). That is Jeremy's
-- call, not a mistake to be "fixed" by a later migration.

begin;

-- Guard the starting state. If Senior Night has already been moved, or sits on
-- more than one row, stop rather than guess which one is authoritative.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'expected exactly 1 Senior Night row in 2026-27, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
     and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'Senior Night is not on the 2026-09-04 varsity game (matched % rows)', n;
  end if;
end $$;

-- The destination must exist, be the only game that day, and be unmarked -
-- overwriting an existing note here would silently drop it.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09';
  if n <> 1 then
    raise exception 'expected exactly 1 game on 2026-10-09, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09'
     and opponent = 'Stony Point High School'
     and home_or_away = 'home'
     and notes is null;
  if n <> 1 then
    raise exception 'the 2026-10-09 varsity Stony Point home game is not present and unmarked (matched % rows)', n;
  end if;
end $$;

update games
set notes = null
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
  and notes = 'Senior Night';

update games
set notes = 'Senior Night'
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-10-09'
  and opponent = 'Stony Point High School'
  and notes is null;

-- End state: one Senior Night in the season, on Oct 9, and the Sept 4 game
-- carries no marker at all. Homecoming must be untouched.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09';
  if n <> 1 then
    raise exception 'Senior Night did not land on 2026-10-09 (matched % rows)', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'expected exactly 1 Senior Night row after the move, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
     and notes is null;
  if n <> 1 then
    raise exception 'the Sept 4 game did not come back clean (matched % rows)', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and notes = 'Homecoming'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-23';
  if n <> 1 then
    raise exception 'Homecoming was disturbed (matched % rows on 2026-10-23)', n;
  end if;
end $$;

commit;

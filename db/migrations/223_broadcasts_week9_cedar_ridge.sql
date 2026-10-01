-- 223_broadcasts_week9_cedar_ridge.sql
--
-- Week 9 broadcast links: varsity at Cedar Ridge (Cedar Ridge home) at KRAC,
-- Fri Oct 2, 7:00 p.m. From Jeremy 2026-10-01, the day before the game:
--
--   VYPE     https://www.vype.com/7pm-football-cedar-ridge-vs-mcneil-2677949441
--   YouTube  https://youtube.com/live/hQwJ091W1A0
--
-- Both verified before writing: 200 under a desktop UA. VYPE og:title
-- "7PM - Football: Cedar Ridge vs. McNeil"; YouTube <title> "7PM - Football:
-- McNeil vs. Cedar Ridge". VYPE also broadcasts this game for Cedar Ridge, so
-- its page offers two streams; the McNeil one is the McNeil Broadcast option.
-- The site label stays one word ("VYPE"); the note is not carried.
--
-- Same shape and rules as 216: YouTube sort 1, VYPE sort 2, keep_after_final
-- = false on both (180), game selected by identity, re-run inert. Enter the
-- result Friday night/Saturday so the links retire.
--
-- Row counts: before, 2026-27 varsity carries 10 broadcast rows, 8 active.
-- After: 12 and 10.
--
-- DB-ONLY, NO DEPLOY. Rollback: 223_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-02 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-03 00:00 America/Chicago'
     and g.opponent = 'Cedar Ridge High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Cedar Ridge game on Oct 2, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 10 then raise exception 'expected 10 varsity broadcast rows before 223, found % (already applied?)', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/hQwJ091W1A0', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-cedar-ridge-vs-mcneil-2677949441', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-10-02 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-10-03 00:00 America/Chicago'
  and g.opponent = 'Cedar Ridge High School'
on conflict (game_id, url) do nothing;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-02 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-03 00:00 America/Chicago'
     and g.opponent = 'Cedar Ridge High School';

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Cedar Ridge game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/hQwJ091W1A0'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-cedar-ridge-vs-mcneil-2677949441'
     and sort_order = 2 and active and not keep_after_final;
  if n <> 1 then raise exception 'the VYPE row is wrong or missing'; end if;

  -- 180's invariant: no 2026-27 broadcast link outlives the final whistle.
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and gb.keep_after_final;
  if n <> 0 then raise exception '% 2026-27 row(s) have keep_after_final = true', n; end if;

  -- Nothing on sub-varsity games, which VYPE does not carry.
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level <> 'varsity';
  if n <> 0 then raise exception 'broadcast links attached to % non-varsity game(s)', n; end if;

  -- Six varsity weeks, two rows each (Bowie pair inactive since 180, never deleted).
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 12 then raise exception 'expected 12 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 10 then raise exception 'expected 10 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

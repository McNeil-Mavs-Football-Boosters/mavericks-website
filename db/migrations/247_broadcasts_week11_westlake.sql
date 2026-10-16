-- 247_broadcasts_week11_westlake.sql
--
-- Week 11 broadcast links: varsity AT Westlake, Chaparral Stadium,
-- Fri Oct 16, 7:00 p.m. From Jeremy 2026-10-16, game day, pasted as watch
-- pages this time (no preview article):
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-westlake
--   YouTube  https://youtube.com/live/VRAv0KCIkcQ
--
-- Both verified before writing: 200 under a desktop UA; VYPE og:title and
-- YouTube <title> both "7PM - Football: McNeil vs. Westlake". VYPE URL has no
-- numeric suffix (same as 216), taken as pasted.
--
-- Same shape and rules as 216/223/234: YouTube sort 1, VYPE sort 2,
-- keep_after_final = false on both (180), game selected by identity, re-run
-- inert. Enter the result tonight/Saturday so the links retire.
--
-- Row counts: before, 2026-27 varsity carries 14 broadcast rows, 12 active.
-- After: 16 and 14.
--

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-16 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-17 00:00 America/Chicago'
     and g.opponent = 'Westlake High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Westlake game on Oct 16, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 14 then raise exception 'expected 14 varsity broadcast rows before 247, found % (already applied?)', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/VRAv0KCIkcQ', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-westlake', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-10-16 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-10-17 00:00 America/Chicago'
  and g.opponent = 'Westlake High School'
on conflict (game_id, url) do nothing;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-16 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-17 00:00 America/Chicago'
     and g.opponent = 'Westlake High School';

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Westlake game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/VRAv0KCIkcQ'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-mcneil-vs-westlake'
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

  -- Seven varsity weeks, two rows each (Bowie pair inactive since 180, never deleted).
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 16 then raise exception 'expected 16 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 14 then raise exception 'expected 14 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

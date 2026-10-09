-- 234_broadcasts_week10_stony_point.sql
--
-- Week 10 broadcast links: varsity HOME vs Stony Point at KRAC (Senior Night),
-- Fri Oct 9, 7:00 p.m. From Jeremy 2026-10-09, game day. He sent VYPE's
-- PREVIEW ARTICLE (vype.com/vype-central-texas-game-of-the-week-preview-mcneil-vs-stony-point),
-- not a watch page; the article links the real stream, which is what is stored:
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-stony-point-2678007546
--   YouTube  https://youtube.com/live/s9xjruITkiI
--
-- Both verified before writing: 200 under a desktop UA; VYPE og:title and
-- YouTube <title> both "7PM - Football McNeil vs. Stony Point". The article
-- embeds a second YouTube video (n5fzNztQskw) that is "Bowie vs. Hays"; not ours,
-- not stored. Article also says KVUE+ App; not carried (no URL to link).
--
-- Same shape and rules as 216/223: YouTube sort 1, VYPE sort 2, keep_after_final
-- = false on both (180), game selected by identity, re-run inert. Enter the
-- result tonight/Saturday so the links retire.
--
-- Row counts: before, 2026-27 varsity carries 12 broadcast rows, 10 active.
-- After: 14 and 12.
--

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-09 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-10 00:00 America/Chicago'
     and g.opponent = 'Stony Point High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Stony Point game on Oct 9, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 12 then raise exception 'expected 12 varsity broadcast rows before 234, found % (already applied?)', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/s9xjruITkiI', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-stony-point-2678007546', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-10-09 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-10-10 00:00 America/Chicago'
  and g.opponent = 'Stony Point High School'
on conflict (game_id, url) do nothing;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-10-09 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-10-10 00:00 America/Chicago'
     and g.opponent = 'Stony Point High School';

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Stony Point game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/s9xjruITkiI'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-mcneil-vs-stony-point-2678007546'
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
  if n <> 14 then raise exception 'expected 14 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 12 then raise exception 'expected 12 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

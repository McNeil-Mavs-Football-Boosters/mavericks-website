-- 198_broadcasts_week7_vista_ridge.sql
--
-- Week 7 broadcast links: varsity at Vista Ridge (Gupton Stadium), Fri Sep 18,
-- 7:00 p.m. From Jeremy 2026-09-17, the day before the game:
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-vista-ridge-2677859018
--   YouTube  https://youtube.com/live/bu2KuoBMs_0
--
-- ── BOTH VERIFIED BEFORE WRITING, NOT ASSUMED ──
-- Each returned 200 under a desktop user agent and each is titled for THIS
-- game: the VYPE page's og:title and the YouTube page's title both read
-- "7PM - Football: McNeil vs. Vista Ridge". Standing procedure since 180; it is
-- the whole defence against a link pasted from the wrong week.
--
-- ── BOTH ROWS ARE keep_after_final = false. NOT A JUDGMENT CALL. ──
-- 180 retired the "YouTube persists as a replay" policy (Bowie's coach asked
-- for film to come down; Jeremy: links are "only good for about 24 hours after
-- the game"). 195 shipped a `true` for a minute by copying 165's stale comment
-- and now asserts 180's invariant in its guard, as does this file. DO NOT SET
-- keep_after_final = true. Read forward to the newest migration that touches a
-- column before copying the one that created it.
--
-- ── SHAPE, COPIED FROM 195 ──
-- YouTube is sort_order 1 (it is the thing that actually plays), VYPE is 2.
-- One-word labels so the schedule's action column does not widen. The game is
-- selected by identity (year + level + designation + one-day window + opponent),
-- never by a pasted uuid. `on conflict (game_id, url) do nothing` makes a re-run
-- inert, and the guards count rows so an inert re-run cannot pass as an insert.
--
-- ⚠️ `keep_after_final` only fires once the game is marked `final`. The Rouse
-- links stayed up three days because the result sat unentered (196). Enter the
-- Vista Ridge result Friday night or Saturday, or deactivate these rows by hand.
--
-- ⚠️ VYPE IS VARSITY ONLY. The JV and freshman Vista Ridge games (Thu Sep 17)
-- get nothing here; that is not an omission. 199 handles the freshman kickoff.
--
-- ⚠️ NOT THE NEWSLETTER, NOT THE ICS (Jeremy 2026-08-26 and 2026-09-01).
--
-- DB-ONLY, NO DEPLOY. Schedule pages are ISR'd; allow a minute before verifying.
--
-- Rollback: 198_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-18 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-19 00:00 America/Chicago'
     and g.opponent = 'Vista Ridge High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Vista Ridge game on Sep 18, found %', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/bu2KuoBMs_0', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-vista-ridge-2677859018', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-09-18 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-09-19 00:00 America/Chicago'
  and g.opponent = 'Vista Ridge High School'
on conflict (game_id, url) do nothing;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-18 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-19 00:00 America/Chicago'
     and g.opponent = 'Vista Ridge High School';

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Vista Ridge game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/bu2KuoBMs_0'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-mcneil-vs-vista-ridge-2677859018'
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

  -- Four varsity weeks, two rows each (Bowie pair inactive since 180, never deleted).
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 8 then raise exception 'expected 8 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 6 then raise exception 'expected 6 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

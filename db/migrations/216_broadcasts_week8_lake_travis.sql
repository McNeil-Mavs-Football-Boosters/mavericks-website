-- 216_broadcasts_week8_lake_travis.sql
--
-- Week 8 broadcast links: varsity HOME vs Lake Travis at KRAC, Thu Sep 24,
-- 7:00 p.m. From Jeremy 2026-09-23, the day before the game:
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-lake-travis
--   YouTube  https://youtube.com/live/uMgcaGseSxU
--
-- ── BOTH VERIFIED BEFORE WRITING, NOT ASSUMED ──
-- Each returned 200 under a desktop user agent and each is titled for THIS
-- game: the VYPE page's og:title and the YouTube page's <title> both read
-- "7PM - Football: McNeil vs. Lake Travis". Standing procedure since 180; it is
-- the whole defence against a link pasted from the wrong week. (This VYPE URL
-- has no numeric suffix, unlike Lake Belton and Vista Ridge; Rouse had none
-- either. Taken as pasted.)
--
-- ── BOTH ROWS ARE keep_after_final = false. NOT A JUDGMENT CALL. ──
-- 180 retired the "YouTube persists as a replay" policy (Bowie's coach asked
-- for film to come down; Jeremy: links are "only good for about 24 hours after
-- the game"). DO NOT SET keep_after_final = true. Asserted below.
--
-- ── SHAPE, COPIED FROM 195/198 ──
-- YouTube is sort_order 1 (it is the thing that actually plays), VYPE is 2.
-- One-word labels. The game is selected by identity (year + level +
-- designation + one-day window + opponent), never by a pasted uuid.
-- `on conflict (game_id, url) do nothing` makes a re-run inert, and the guards
-- count rows so an inert re-run cannot pass as an insert.
--
-- ⚠️ `keep_after_final` only fires once the game is marked `final`. Enter the
-- Lake Travis result Thursday night or Friday, or deactivate these rows by hand
-- (the Rouse links stayed up three days because the result sat unentered, 196).
--
-- ⚠️ VYPE IS VARSITY ONLY. The JV and freshman Lake Travis games (Wed Sep 23)
-- get nothing here.
--
-- ⚠️ NOT THE NEWSLETTER, NOT THE ICS (Jeremy 2026-08-26 and 2026-09-01). The
-- 9/24 reminder issue drafted today does not carry these, on purpose.
--
-- Row counts: before this file, 2026-27 varsity carries 8 broadcast rows, 6
-- active (Bowie pair inactive since 180; Vista Ridge pair still active in the
-- table, hidden on the page because that game is final). After: 10 and 8.
--
-- DB-ONLY, NO DEPLOY. Schedule pages are ISR'd; allow a minute before verifying.
--
-- Rollback: 216_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-24 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-25 00:00 America/Chicago'
     and g.opponent = 'Lake Travis High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Lake Travis game on Sep 24, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 8 then raise exception 'expected 8 varsity broadcast rows before 216, found % (already applied?)', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/uMgcaGseSxU', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-lake-travis', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-09-24 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-09-25 00:00 America/Chicago'
  and g.opponent = 'Lake Travis High School'
on conflict (game_id, url) do nothing;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-24 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-25 00:00 America/Chicago'
     and g.opponent = 'Lake Travis High School';

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Lake Travis game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/uMgcaGseSxU'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-mcneil-vs-lake-travis'
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

  -- Five varsity weeks, two rows each (Bowie pair inactive since 180, never deleted).
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 10 then raise exception 'expected 10 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 8 then raise exception 'expected 8 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

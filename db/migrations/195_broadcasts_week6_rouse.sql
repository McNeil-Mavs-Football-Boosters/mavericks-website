-- 195_broadcasts_week6_rouse.sql
--
-- Week 6 broadcast links: varsity at Rouse, Fri Sep 11, 7:00 p.m. From Jeremy
-- 2026-09-11, the day of the game:
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-rouse
--   YouTube  https://youtube.com/live/NLfl3zeIPK4
--
-- ── BOTH VERIFIED BEFORE WRITING, NOT ASSUMED ──
-- Each returned 200 and each is titled for THIS game: the VYPE page's og:title
-- and the YouTube page's title both read "7PM - Football: McNeil vs. Rouse".
-- That check is the standing procedure (180) and it is the whole defence
-- against a link pasted from the wrong week -- a VYPE slug for another game is
-- still a 200 page.
--
-- ── BOTH ROWS ARE keep_after_final = false. THIS IS NOT A JUDGMENT CALL. ──
-- 🚨 THE FIRST DRAFT OF THIS MIGRATION SET THE YouTube ROW TO `true` AND WAS
-- APPLIED THAT WAY FOR ABOUT A MINUTE BEFORE BEING CORRECTED. It copied 165's
-- shape, whose comment still says a YouTube live URL "persists as a replay" and
-- that Jeremy wants it kept up afterwards. **That comment is stale and 180
-- retired the policy it describes**: Merle Bertrand at VYPE, 2026-09-01, "I had
-- to hide last week's at the request of Bowie's coach," and Jeremy the same day
-- said the links should "only be good for about 24 hours after the game." 180
-- deactivated the Aug 28 replay and set the rule in capitals: **DO NOT SET
-- keep_after_final = true AGAIN.** Opposing coaches ask for film to come down
-- and the club is not the party that gets to refuse.
--
-- ⚠️ **THE LESSON IS ABOUT WHERE THE POLICY LIVES, NOT ABOUT THIS ONE FLAG.**
-- 165 is the migration that CREATED the table, so it reads like the canonical
-- description of every column, and its comment is wrong. Copying the oldest,
-- most authoritative-looking migration is exactly how the retired policy came
-- back. **Read forward to the newest migration that touches a column before
-- copying the one that created it.** The final guard below now asserts 180's
-- invariant directly -- zero 2026-27 rows with `keep_after_final` -- so the next
-- attempt fails loudly instead of shipping a replay somebody has to ask to have
-- taken down.
--
-- ── REMAINING SHAPE, COPIED FROM 180 ──
-- YouTube is sort_order 1 (it is the thing that actually plays), VYPE is 2.
-- Labels stay one word each so the schedule's action column does not widen.
--
-- The game is selected by its ACTUAL IDENTITY -- year + level + designation +
-- a one-day date window + opponent -- and never by a pasted uuid, so this fails
-- loudly if the row moved rather than silently attaching links to nothing.
-- `on conflict (game_id, url) do nothing` makes a re-run inert, and the guards
-- below count rows so an inert re-run cannot look like a successful insert.
--
-- ⚠️ `keep_after_final` only fires once the game is marked `final`, so "24
-- hours" depends on somebody entering the result. Same dependency 174 and 180
-- both flagged; it is load-bearing for something a coach has actually
-- complained about.
--
-- ⚠️ VYPE IS VARSITY ONLY. The JV and freshman games against Rouse (Sep 10) get
-- nothing here; that is not an omission.
--
-- ⚠️ NOT THE NEWSLETTER, NOT THE ICS -- both are Jeremy's standing calls from
-- 2026-08-26 and neither has been revisited. A link in a sent email cannot be
-- revoked and a per-game VYPE URL is exactly the kind that rots, so the durable
-- thing to print is the "Broadcast Lineup" pointer. ICS descriptions are plain
-- prose with no URLs by convention (migration 156), and broadcast links do not
-- belong in someone's subscribed calendar.
--
-- DB-ONLY, NO DEPLOY. The render code shipped with 165; this is two rows.
-- ⚠️ The schedule pages are ISR'd, so allow a minute before verifying.
--
-- Rollback: 195_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-11 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-12 00:00 America/Chicago'
     and g.opponent = 'Rouse High School';
  if n <> 1 then raise exception 'expected exactly 1 varsity Rouse game on Sep 11, found %', n; end if;
end $$;

insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
from games g
cross join (values
    ('YouTube', 'https://youtube.com/live/NLfl3zeIPK4', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-rouse', 2)
  ) as v(label, url, sort_order)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-09-11 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-09-12 00:00 America/Chicago'
  and g.opponent = 'Rouse High School'
on conflict (game_id, url) do nothing;

-- Corrective, and deliberately NOT folded into the insert above: the first
-- draft of this migration reached the live database with the YouTube row set to
-- `keep_after_final = true`. `on conflict do nothing` will not repair a row that
-- already exists, so re-running a fixed insert alone would leave prod wrong and
-- the guard below would fail with no way forward. This makes the file
-- self-healing and idempotent against both a fresh database and the one that
-- briefly held the bad value.
update game_broadcasts gb
   set keep_after_final = false, updated_at = now()
  from games g
 where g.id = gb.game_id
   and g.year = '2026-27'
   and gb.keep_after_final;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27'
     and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-09-11 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-09-12 00:00 America/Chicago'
     and g.opponent = 'Rouse High School';

  -- Exactly two active links on the right game.
  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then raise exception 'expected 2 active broadcast rows on the Rouse game, found %', n; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube'
     and url = 'https://youtube.com/live/NLfl3zeIPK4'
     and sort_order = 1 and active and not keep_after_final;
  if n <> 1 then raise exception 'the YouTube row is wrong or missing'; end if;

  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'VYPE'
     and url = 'https://www.vype.com/7pm-football-mcneil-vs-rouse'
     and sort_order = 2 and active and not keep_after_final;
  if n <> 1 then raise exception 'the VYPE row is wrong or missing'; end if;

  -- 🚨 180's INVARIANT, RESTATED HERE BECAUSE THIS MIGRATION BROKE IT ONCE.
  -- No 2026-27 broadcast link outlives the final whistle. The only
  -- keep_after_final row in the table belongs to the 2025-26 season (the
  -- iHSFan CHANNEL url from 052, which is not a per-game broadcast and does
  -- not rot).
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and gb.keep_after_final;
  if n <> 0 then raise exception '% 2026-27 row(s) still have keep_after_final = true', n; end if;

  -- Nothing leaked onto the sub-varsity Rouse games, which VYPE does not carry.
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level <> 'varsity';
  if n <> 0 then raise exception 'broadcast links attached to % non-varsity game(s)', n; end if;

  -- Three varsity weeks, two rows each. The Aug 28 pair is inactive (180 pulled
  -- the replay) and still counted -- rows are deactivated, never deleted.
  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity';
  if n <> 6 then raise exception 'expected 6 broadcast rows across 2026-27 varsity, found %', n; end if;

  select count(*) into n from game_broadcasts gb join games g on g.id = gb.game_id
   where g.year = '2026-27' and g.team_level = 'varsity' and gb.active;
  if n <> 4 then raise exception 'expected 4 ACTIVE varsity broadcast rows, found %', n; end if;
end $$;

commit;

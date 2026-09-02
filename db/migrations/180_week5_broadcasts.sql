-- 180_week5_broadcasts.sql
--
-- Two things, both about how long a broadcast link should live.
--
--   1. PULL DOWN last week's Aug 28 replay.
--   2. ADD this week's Sep 4 links (VYPE + YouTube), set to expire the same way.
--
-- ── 1. THE REPLAY COMES DOWN, AND THE POLICY CHANGES WITH IT ──
-- 165 gave the YouTube row `keep_after_final = true` on the theory that it
-- becomes a durable replay. **That theory is retired.** Merle Bertrand at VYPE,
-- 2026-09-01: "Coach never responded about hiding the replays, but I had to hide
-- last week's at the request of Bowie's coach." Jeremy's call the same day: the
-- links should "only be good for about 24 hours after the game."
--
-- So a broadcast link is now a LIVE link with a short tail, not an archive. The
-- Aug 28 YouTube row is deactivated rather than deleted, so the URL survives in
-- the table if anyone ever needs it, and every new row goes in with
-- `keep_after_final = false`.
--
-- ⚠️ **DO NOT SET keep_after_final = true AGAIN** on the strength of 165's
-- comment, which still describes YouTube as "it persists as a replay". That is
-- now wrong and this migration is the reason. Opposing coaches ask for film to
-- come down, and the club is not the party that gets to refuse.
--
-- ⚠️ `keep_after_final` only fires once the game is marked `final`, so it is an
-- approximation of "24 hours" and depends on somebody entering the result. If
-- results stop being entered promptly the links overstay. That is the same
-- dependency flagged in 174, and it is now load-bearing for something a coach
-- has actually complained about, not just for a tidy schedule page.
--
-- ── 2. WEEK 5 LINKS ──
-- Merle's mail to Carol, 2026-09-01. Both verified before insert: HTTP 200 under
-- a normal desktop user agent, and BOTH page titles read
-- "7PM - Football: McNeil vs. Lake Belton", which names THIS week's opponent.
-- That title check is the standing procedure and it is what catches a link
-- pasted from the wrong week.
--
--   VYPE     https://www.vype.com/7pm-football-mcneil-vs-lake-belton-2677796708
--   YouTube  https://youtube.com/live/8vejbL5NTLY
--
-- Merle: "We simply embed the YouTube link on VYPE.com, so either will work."
-- Both are published anyway because they fail differently: the VYPE page is a
-- vendor page that rots, the YouTube link is the stream itself.
--
-- Sort order puts YouTube first, matching Aug 28.
--
-- ⚠️ Unrelated pre-existing row noticed while doing this and deliberately NOT
-- touched: a `Watch` link on a **2025-11-07 varsity game vs Hutto** pointing at
-- `youtube.com/@iHSFan`, a channel homepage rather than a game. It is LAST
-- SEASON'S row (2025-26), not this one, which is why the guards below scope to
-- year = '2026-27' rather than trying to except it by date. A first draft
-- excepted "2026-11-07" and failed, which is how the year was noticed at all.
-- Worth a look someday; not this migration's business.
--
-- DB-ONLY, NO DEPLOY. /schedule/games/varsity reads at request time.
--
-- Rollback: 180_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.year = '2026-27' and g.team_level = 'varsity'
     and g.game_date = timestamptz '2026-08-28 19:30 America/Chicago'
     and b.label = 'YouTube' and b.active;
  if n <> 1 then raise exception 'Aug 28 YouTube row not found active (found %)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-04 19:00 America/Chicago';
  if n <> 1 then raise exception 'Sep 4 varsity game not found'; end if;

  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-04 19:00 America/Chicago';
  if n <> 0 then raise exception 'Sep 4 already has % broadcast rows', n; end if;
end $$;

-- 1. Last week's replay comes down. Deactivated, not deleted.
-- Also clears keep_after_final so no 2026-27 row is left carrying the retired
-- "it persists as a replay" policy, even a hidden one.
update game_broadcasts b
   set active = false, keep_after_final = false, updated_at = now()
  from games g
 where g.id = b.game_id
   and g.year = '2026-27' and g.team_level = 'varsity'
   and g.game_date = timestamptz '2026-08-28 19:30 America/Chicago';

-- 2. This week, both with keep_after_final = false so they age out on their own.
insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final, active)
select g.id, v.label, v.url, v.sort_order, false, true
  from games g
  cross join (values
    ('YouTube', 'https://youtube.com/live/8vejbL5NTLY', 1),
    ('VYPE',    'https://www.vype.com/7pm-football-mcneil-vs-lake-belton-2677796708', 2)
  ) as v(label, url, sort_order)
 where g.year = '2026-27' and g.team_level = 'varsity'
   and g.game_date = timestamptz '2026-09-04 19:00 America/Chicago';

do $$
declare n int;
begin
  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and b.active and b.keep_after_final = false;
  if n <> 2 then raise exception 'expected 2 active Sep 4 rows with keep_after_final false, found %', n; end if;

  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.game_date = timestamptz '2026-08-28 19:30 America/Chicago' and b.active;
  if n <> 0 then raise exception '% Aug 28 broadcast rows are still active', n; end if;

  -- No 2026-27 row may still claim to survive a final. Scoped by YEAR: the only
  -- other keep_after_final row in the table belongs to the 2025-26 season.
  select count(*) into n from game_broadcasts b join games g on g.id = b.game_id
   where g.year = '2026-27' and b.keep_after_final;
  if n <> 0 then raise exception '% 2026-27 rows still have keep_after_final = true', n; end if;
end $$;

commit;

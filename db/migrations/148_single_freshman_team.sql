-- 148_single_freshman_team.sql
--
-- McNeil is fielding ONE freshman team in 2026-27, not two. Coach told Jeremy
-- 2026-08-17. This was always the anticipated case -- `freshman_has_blue` exists
-- for exactly this -- so it is a flag flip plus retiring the Blue roster row,
-- not a structural change.
--
-- What the flag does on its own, no code change required:
--   * /roster/freshman/blue and /schedule/games/freshman/blue both notFound()
--   * `showDesignation` goes false, so every user-visible label drops the colour
--     and reads plain "Freshmen" -- which is precisely Jeremy's "just Green or
--     no color". The URL keeps /green; only the wording changes.
--   * Both Blue entries leave the header and mobile nav (buildScheduleLinks /
--     buildRosterLinks).
--   * The practice page title stops reading "Freshmen Green & Blue".
--   * getGamesAsEvents drops every freshman Blue row, so /events, the month view
--     and the ICS feed lose them too.
--
-- ── ⚠️ THE 12 FRESHMAN BLUE GAME ROWS ARE LEFT IN PLACE, DELIBERATELY ──
-- The flag already makes them unreachable on every surface, so deleting them
-- buys nothing and costs the one thing still unresolved: Blue and Green are the
-- SAME 12 fixtures -- identical opponent, venue and home/away on every date --
-- differing only in kickoff time. The two scrimmages (Aug 13, Aug 20) are 5:30
-- for both, but all 10 regular-season games are Blue 5:00 p.m. vs Green 6:30 p.m.
--
-- Nobody has yet said which of those two slots the single team plays. Green
-- survives, so the site currently publishes 6:30. If the answer turns out to be
-- 5:00, the Blue rows ARE the record of that timing and the fix is one UPDATE
-- against them. Throwing them away would mean re-deriving a time we already
-- have on file.
--
-- ⚠️ DO NOT let this sit unanswered past Thu Aug 27, the first affected game.
-- The Aug 20 Eastview scrimmage is unaffected (5:30 either way).
--
-- Rollback: 148_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from site_settings where freshman_has_blue;
  if n <> 1 then
    raise exception 'Expected freshman_has_blue = true before this migration, found % row(s) set', n;
  end if;

  select count(*) into n
    from rosters where year = '2026-27' and team_level = 'freshman' and active;
  if n <> 2 then
    raise exception 'Expected 2 active 2026-27 freshman rosters (Green + Blue), found %', n;
  end if;
end $$;

update site_settings set freshman_has_blue = false;

-- Deactivated, not deleted -- the project's standing pattern (111 Rudy's,
-- 113 Program Ad, 147 Stadiums). The row carries its id and created_at, and
-- the roster pages already filter on active.
update rosters
   set active = false
 where year = '2026-27'
   and team_level = 'freshman'
   and team_designation = 'Blue';

do $$
declare n int;
begin
  select count(*) into n
    from rosters where year = '2026-27' and team_level = 'freshman' and active;
  if n <> 1 then
    raise exception 'Expected exactly 1 active 2026-27 freshman roster after the flip, found %', n;
  end if;

  select count(*) into n from site_settings where freshman_has_blue;
  if n <> 0 then
    raise exception 'freshman_has_blue is still set on % row(s)', n;
  end if;
end $$;

commit;

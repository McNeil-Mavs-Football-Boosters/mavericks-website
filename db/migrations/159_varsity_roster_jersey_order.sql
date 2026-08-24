-- 159_varsity_roster_jersey_order.sql
--
-- Re-sort the 2026-27 varsity roster by JERSEY NUMBER ascending. Jeremy,
-- 2026-08-24.
--
-- ── WHAT WAS WRONG ──
-- 157 assigned sort_order 1..45 in the spreadsheet's READING order: the sheet
-- lays the roster out in two side-by-side blocks (cols A-D and E-H) and the
-- parser walked it row by row, taking the left cell then the right one. That
-- interleaves the two blocks -- 0, 26, 1, 27, 3, 28, ... -- which is right for
-- the PRINTED page, where the eye reads across, and wrong for the website,
-- where there is a single column and the roster should just count up.
--
-- The fix is to read DOWN the first block and then down the second, which is
-- identical to ordering by jersey number, because each block is already
-- jersey-ascending. So this orders by the number itself rather than by
-- position -- it cannot drift if the sheet's layout ever changes.
--
-- ⚠️ THE PDF IS NOT AFFECTED AND MUST NOT BE "FIXED" TO MATCH. The two-block
-- print layout is what the coaching staff sent and what people tape to a wall;
-- reading across is correct there. The website and the PDF are supposed to
-- differ on this one thing.
--
-- ── ORDER BY THE FIRST NUMBER LISTED ──
-- Five players wear two numbers and are stored as 'a/b' after 158 stripped the
-- parens: 5/2, 8/18, 9/10, 64/65, 84/80. Jeremy's rule is the FIRST number
-- listed, so split_part(jersey_number, '/', 1) is the sort key: 5/2 sorts at 5,
-- 84/80 at 84. Verified no collision -- the 45 leading numbers are distinct.
--
-- ⚠️ The cast to int is deliberate and the guard below exists to protect it.
-- Ordering these as TEXT would put '11' before '3', and every roster bug in
-- this project so far has been a lexicographic sort wearing a numeric costume.
--
-- ⚠️ WHY sort_order HAS TO CARRY THIS AT ALL, rather than letting the component
-- sort: components/roster/player-table.tsx sorts by sort_order FIRST and only
-- then by jersey. Its jerseyKey() does `Number(trimmed)`, so '5/2' is NaN and
-- becomes +Infinity -- if sort_order ever tied, the five dual-number players
-- would all sink to the bottom of the table. sort_order being dense and correct
-- is what keeps that latent bug from ever firing.
--
-- DB-ONLY, NO DEPLOY. Roster pages render on demand.
--
-- Rollback: 159_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if n <> 45 then
    raise exception 'expected the 45 varsity rows, found %', n;
  end if;

  -- Fail with a readable message rather than letting ::int throw mid-statement.
  -- After 158 every jersey is digits, optionally digits/digits. Anything else
  -- means the roster gained a value nobody has looked at.
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null
     and p.jersey_number !~ '^[0-9]+(/[0-9]+)?$';
  if n <> 0 then
    raise exception '% jersey number(s) are not digits or digits/digits - cannot order numerically', n;
  end if;
end $$;

with ranked as (
  select p.id,
         row_number() over (
           order by split_part(p.jersey_number, '/', 1)::int
         ) as rn
    from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27'
     and r.team_level = 'varsity'
     and r.team_designation is null
)
update players p
   set sort_order = ranked.rn
  from ranked
 where ranked.id = p.id;

-- Count, then assert.
do $$
declare n int; j text;
begin
  select count(distinct sort_order) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if n <> 45 then
    raise exception 'sort_order is not unique across the 45 rows (% distinct)', n;
  end if;

  select min(sort_order) || '-' || max(sort_order) into j from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if j <> '1-45' then
    raise exception 'sort_order is not a dense 1..45 range (got %)', j;
  end if;

  -- Spot-check the three that would break first: jersey 0 must lead (a falsy-0
  -- bug would drop him), 90 must trail, and the dual number 5/2 must sit at 5
  -- rather than sorting as text or sinking to the end.
  select p.jersey_number into j from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.sort_order = 1;
  if j <> '0' then raise exception 'expected jersey 0 first, got %', j; end if;

  select p.jersey_number into j from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.sort_order = 45;
  if j <> '90' then raise exception 'expected jersey 90 last, got %', j; end if;

  select p.jersey_number into j from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.sort_order = 5;
  if j <> '5/2' then raise exception 'expected 5/2 at position 5, got %', j; end if;
end $$;

commit;

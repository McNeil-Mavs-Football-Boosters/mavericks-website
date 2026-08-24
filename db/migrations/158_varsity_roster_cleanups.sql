-- 158_varsity_roster_cleanups.sql
--
-- Two corrections to the 45 varsity players seeded by 157, both confirmed by
-- Jeremy 2026-08-24 after he took them back to the source.
--
--   1. Drop the wrapping parentheses from the three parenthesised dual jersey
--      numbers, so all five dual numbers read the same way.
--          '(5/2)'  -> '5/2'
--          '(8/18)' -> '8/18'
--          '(9/10)' -> '9/10'
--      '64/65' and '84/80' were already bare and are untouched. The source
--      spreadsheet is inconsistent about it; the coaches' meaning is identical
--      either way, so this is presentation, not data.
--
--   2. 'DL/ LB' -> 'DL/LB' (Jesus Galaza, #90). Confirmed a typo -- every other
--      slash position in the sheet has no spaces. This is the ONLY position
--      cell with whitespace around its slash.
--
-- ⚠️ 157's header says positions and jersey strings are stored VERBATIM. That
-- was correct at the time -- the rule then was "do not silently normalise the
-- coaches' data." It is superseded HERE, and only for these two rules, because
-- Jeremy went and confirmed both. Do not read 157 alone and "restore" the
-- parens or the space.
--
-- ⚠️ THE SAME TWO RULES ALSO LIVE IN scripts/make-varsity-roster-pdf.py
-- (normalize_jersey / normalize_position), because the downloadable PDF is
-- generated from the spreadsheet and not from this table. The site and the
-- printed roster have to agree. If you change one, change the other.
--
-- ── The staff-block question from 157 is RESOLVED, and it was never a conflict ──
-- 157 left rosters.body empty because the spreadsheet's credit block named Jeff
-- Cheatham as Athletic Director while /coaches has Jerry Gardner as "Head Coach
-- and Athletic Director". Jeremy 2026-08-24: **Gardner is the McNeil AD;
-- Cheatham is the ROUND ROCK ISD (district) AD.** Different jobs, both right.
-- Nothing to fix on /coaches, and the PDF keeps the credit block exactly as the
-- coaching staff sent it. body stays empty -- that was never the reason to fill
-- it in.
--
-- Also updates pdf_storage_path to the regenerated PDF. It goes to a NEW
-- FILENAME rather than overwriting varsity-2026.pdf on purpose: Storage serves
-- no-cache but next.config.ts sets minimumCacheTTL to 31 days, and replacing an
-- object at a live path has served stale bytes before. New name + UPDATE is the
-- house rule. The old object is left in the bucket; nothing points at it.
--
-- DB-ONLY, NO DEPLOY. Roster pages render on demand.
--
-- Rollback: 158_rollback.sql

begin;

-- Guard: 157 must have run, and these rows must still look the way it left them.
-- If someone has already hand-fixed them, stop rather than report a false count.
do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if n <> 45 then
    raise exception 'expected the 45 rows seeded by 157, found %', n;
  end if;

  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null
     and p.jersey_number like '(%)';
  if n <> 3 then
    raise exception 'expected 3 parenthesised jersey numbers, found %', n;
  end if;

  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null
     and p.position ~ '\s/|/\s';
  if n <> 1 then
    raise exception 'expected exactly 1 position with whitespace around its slash, found %', n;
  end if;
end $$;

-- 1. Unwrap the parenthesised jersey numbers.
--    Anchored ^\(...\)$ so it only ever fires on a WHOLE wrapped cell, matching
--    normalize_jersey() in the PDF generator.
update players p
   set jersey_number = regexp_replace(p.jersey_number, '^\((.*)\)$', '\1')
  from rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and r.team_designation is null
   and p.jersey_number ~ '^\(.*\)$';

-- 2. Close the gap around the slash. Mirrors normalize_position().
update players p
   set position = regexp_replace(p.position, '\s*/\s*', '/', 'g')
  from rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and r.team_designation is null
   and p.position ~ '\s/|/\s';

-- 3. Point Print View at the regenerated PDF.
update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r2.pdf'
 where year = '2026-27'
   and team_level = 'varsity'
   and team_designation is null;

-- Count, then assert.
do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null
     and (p.jersey_number ~ '[()]' or p.position ~ '\s');
  if n <> 0 then
    raise exception 'still % row(s) with a paren or a space in jersey/position', n;
  end if;

  -- The five dual numbers must all survive as bare "a/b".
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null
     and p.jersey_number like '%/%';
  if n <> 5 then
    raise exception 'expected 5 dual jersey numbers, found %', n;
  end if;

  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r2.pdf';
  if n <> 1 then
    raise exception 'pdf_storage_path did not update (% rows)', n;
  end if;
end $$;

commit;

-- 201_varsity_roster_r5.sql
--
-- Varsity roster update from the coaching staff's revised export
-- ("McNeil Varsity Roster - Var Roster 8_21.pdf", a Google Sheets PDF export of
-- the same 'Var Roster 821' sheet 157 was seeded from), given to Claude by Jeremy
-- 2026-09-18. Roster goes 46 -> 49 players and the Print View PDF is repointed
-- at the regenerated r5 export.
--
-- ── JEREMY SAID "UPDATED". THE DIFF FOUND SEVEN THINGS. ──
-- Per 168/200's rule the coaches' PDF was parsed by value and diffed against the
-- live roster (46 rows, r4) by jersey AND by name. Nothing else changed.
--
--   1. #15 Lucas Rosilmo   DB  Sr.   REMOVED  (his number goes to 2)
--   2. #15 Antonio Showels RB  So.   NEW      (also JV #0 -- playing up, like 183)
--   3. #24 TK Keller       LB  So.   NEW      (2025-26 freshman Green #15)
--   4. #37 Kevonn Conner   DB/WR Sr. NEW
--   5. #82 Henion Kim      K   Fr.   NEW      (also freshman Green #10, no position there)
--   6. Jace Hicks          '64/65' -> '64'    (dual number collapsed to one)
--   7. Trainers credit drops Xander Keller    (PDF only; the staff block is not in the DB)
--
-- ⚠️ 6 IS THE OPPOSITE OF 171'S WARNING AND IS STILL APPLIED. 171 established
-- that a slash means real home/away jerseys and must not be "tidied". This is
-- not tidying: the coaches' own export now lists him as 64 only, and the
-- standing rule (166/168/186/200) is that page and poster come from the coaches'
-- artefact and may not disagree with it or each other. Three slash jerseys
-- remain ('5/2', '8/18', '84/80') and the verify block asserts exactly three.
-- Flagged to Jeremy in the same message as this migration.
--
-- ⚠️ ONE DELIBERATE DIVERGENCE FROM THE COACHES' PDF: it spells #10 'Aymane
-- Elanssari'. The DB, the 2025 JV PDF (031) and the original 2026 varsity
-- workbook (157) all say 'El Anssari', so the coaches' artefacts disagree with
-- each other 2:1. Kept as 'El Anssari' on both the page and the r5 PDF (the
-- workbook cell was NOT changed) so the two agree with each other; flagged to
-- Jeremy. If he says 'Elanssari' is right it is one UPDATE plus a workbook
-- edit plus an r6 upload -- not a DB-only fix (176 rule).
--
-- ── SHOWELS AND KIM ARE ALSO ON OTHER ROSTERS AND THAT IS NOT A DUPLICATE ──
-- 183's rule: playing up is normal, and each roster lists the player as its
-- own staff sheet does. Showels stays JV #0 RB; Kim stays freshman #10. Do NOT
-- deduplicate. Kim's grade is 'Fr.' -- the same 'Sr.'/'Jr.'/'So.' form 157
-- chose, and how every 2025-26 freshman row is stored.
--
-- ── ROSILMO IS DELETED, NOT DEACTIVATED ──
-- Every varsity guard since 183 counts rows (`count(*) from players where
-- roster_id = rid`), not active rows, so an inactive leftover would make the
-- next migration's precondition lie. His full row is in 201_rollback.sql.
--
-- ── sort_order IS RECOMPUTED, NOT HAND-PATCHED ──
-- 159/171/183 convention: dense from 1, ordered by the LEADING number of
-- jersey_number ('5/2' sorts as 5, '84/80' as 84). Guarded first by asserting
-- the existing 46 are already in that order, so a silent reshuffle cannot hide
-- inside this change.
--
-- ── THE PDF IS THE OTHER HALF, DONE IN THE SAME SITTING (178/186) ──
-- The coaches' workbook (`roster_pdf/source/Varsity McNeil Roster 2026.xlsx`,
-- gitignored, on Jeremy's disk) was rewritten to the PDF's two-block layout
-- (now 24 left / 25 right, staff block moved down two rows) and
-- `scripts/make-varsity-roster-pdf.py` regenerated it: one page, "49 players:
-- 24 left block, 25 right block", diffed by value against the coaches' PDF
-- with the one divergence above. Uploaded as
-- `documents/rosters/varsity-2026-r5.pdf` -- NEW FILENAME, NOT AN OVERWRITE
-- (158's cache rule), `apikey` header (186), sha256-identical round trip
-- verified before this was written. r4 stays in the bucket for the rollback.
-- Coaches' PDF pinned at `roster_pdf/source/varsity-2026-r5-source.pdf`; the
-- r4 workbook and PDF archived under `roster_pdf/source/archive/`.
--
-- DB-ONLY, NO DEPLOY. /roster/varsity and the Print View link read at request time.
--
-- Rollback: 201_rollback.sql

begin;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf';
  if rid is null then raise exception 'varsity roster not found on r4 (already applied?)'; end if;

  select count(*) into n from players where roster_id = rid;
  if n <> 46 then raise exception 'expected 46 varsity players before this migration, found %', n; end if;

  if (select count(*) from players where roster_id = rid and jersey_number = '15'
        and first_name = 'Lucas' and last_name = 'Rosilmo' and position = 'DB' and grade = 'Sr.') <> 1 then
    raise exception 'Lucas Rosilmo is not #15 DB Sr.'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '64/65'
        and first_name = 'Jace' and last_name = 'Hicks') <> 1 then
    raise exception 'Jace Hicks is not 64/65'; end if;
  if (select count(*) from players where roster_id = rid
        and split_part(jersey_number, '/', 1) in ('24', '37', '82')) <> 0 then
    raise exception '#24 / #37 / #82 already taken on varsity'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number like '%/%') <> 4 then
    raise exception 'expected 4 slash jerseys before this migration'; end if;

  -- The 46 existing rows must already be in leading-number order, or the
  -- recomputation below would quietly reorder the whole roster.
  select count(*) into n from (
    select p.sort_order,
           row_number() over (order by split_part(p.jersey_number, '/', 1)::int) as rn
      from players p where p.roster_id = rid
  ) t where t.sort_order <> t.rn;
  if n <> 0 then raise exception '% varsity row(s) are not in leading-number sort order; stopping', n; end if;

  -- The other rosters this touches by implication must look as expected.
  if (select count(*) from players p join rosters r on r.id = p.roster_id
       where r.year = '2026-27' and r.team_level = 'jv'
         and p.first_name = 'Antonio' and p.last_name = 'Showels' and p.jersey_number = '0') <> 1 then
    raise exception 'JV Antonio Showels #0 not found'; end if;
  if (select count(*) from players p join rosters r on r.id = p.roster_id
       where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green'
         and p.first_name = 'Henion' and p.last_name = 'Kim' and p.jersey_number = '10') <> 1 then
    raise exception 'freshman Henion Kim #10 not found'; end if;
end $$;

-- 1. Rosilmo off the roster.
delete from players p
 using rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '15' and p.first_name = 'Lucas' and p.last_name = 'Rosilmo';

-- 2-5. Four new players. sort_order 0 here; re-densified below.
insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, v.jersey, v.fn, v.ln, v.pos, v.grade, 0, true
  from rosters r
  cross join (values
    ('15', 'Antonio', 'Showels', 'RB',    'So.'),
    ('24', 'TK',      'Keller',  'LB',    'So.'),
    ('37', 'Kevonn',  'Conner',  'DB/WR', 'Sr.'),
    ('82', 'Henion',  'Kim',     'K',     'Fr.')
  ) as v(jersey, fn, ln, pos, grade)
 where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null;

-- 6. Hicks to a single number.
update players p
   set jersey_number = '64', updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '64/65' and p.first_name = 'Jace' and p.last_name = 'Hicks';

-- Re-densify sort_order in leading-number order (159/171/183).
with ordered as (
  select p.id,
         row_number() over (order by split_part(p.jersey_number, '/', 1)::int) as rn
    from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
)
update players p
   set sort_order = o.rn, updated_at = now()
  from ordered o
 where o.id = p.id and p.sort_order is distinct from o.rn;

-- The other half: Print View to the r5 export.
update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf',
       source_note = 'Varsity roster provided by the McNeil coaching staff, received 2026-08-24; revised export received 2026-09-18 (#15 Showels, #24 Keller, #37 Conner, #82 Kim added; Rosilmo removed; Hicks 64)',
       updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null;

  select count(*) into n from players where roster_id = rid;
  if n <> 49 then raise exception 'expected 49 varsity players, found %', n; end if;

  if (select count(*) from players where roster_id = rid and last_name = 'Rosilmo') <> 0 then
    raise exception 'Rosilmo still present'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '15'
        and first_name = 'Antonio' and last_name = 'Showels' and position = 'RB' and grade = 'So.' and active) <> 1 then
    raise exception 'Showels row is not as intended'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '24'
        and first_name = 'TK' and last_name = 'Keller' and position = 'LB' and grade = 'So.' and active) <> 1 then
    raise exception 'Keller row is not as intended'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '37'
        and first_name = 'Kevonn' and last_name = 'Conner' and position = 'DB/WR' and grade = 'Sr.' and active) <> 1 then
    raise exception 'Conner row is not as intended'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '82'
        and first_name = 'Henion' and last_name = 'Kim' and position = 'K' and grade = 'Fr.' and active) <> 1 then
    raise exception 'Kim row is not as intended'; end if;
  if (select count(*) from players where roster_id = rid and jersey_number = '64'
        and first_name = 'Jace' and last_name = 'Hicks') <> 1 then
    raise exception 'Hicks is not 64'; end if;

  -- 171's finding, less the one the coaches themselves collapsed.
  if (select count(*) from players where roster_id = rid and jersey_number like '%/%') <> 3 then
    raise exception 'expected 3 slash jerseys after this migration'; end if;

  -- Nobody shares a leading number.
  select count(*) into n from (
    select split_part(jersey_number, '/', 1) k from players where roster_id = rid
     group by 1 having count(*) > 1) d;
  if n <> 0 then raise exception '% duplicate jersey numbers', n; end if;

  -- sort_order is dense 1..49 in leading-number order.
  select count(*) into n from (
    select sort_order, row_number() over (order by split_part(jersey_number, '/', 1)::int) as rn
      from players where roster_id = rid
  ) t where t.sort_order <> t.rn;
  if n <> 0 then raise exception '% varsity row(s) out of order after recompute', n; end if;
  if (select count(distinct sort_order) from players where roster_id = rid) <> 49 then
    raise exception 'duplicate sort_order values'; end if;

  -- Every varsity row still has a position and a grade (the em-dash rule must not creep).
  if (select count(*) from players where roster_id = rid and (position is null or grade is null)) <> 0 then
    raise exception 'a varsity row lost its position or grade'; end if;

  -- The JV and freshman rows for the two play-up players were not disturbed.
  if (select count(*) from players p join rosters r on r.id = p.roster_id
       where r.year = '2026-27' and r.team_level = 'jv'
         and p.first_name = 'Antonio' and p.last_name = 'Showels' and p.jersey_number = '0') <> 1 then
    raise exception 'the JV Showels row was disturbed'; end if;
  if (select count(*) from players p join rosters r on r.id = p.roster_id
       where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green'
         and p.first_name = 'Henion' and p.last_name = 'Kim' and p.jersey_number = '10') <> 1 then
    raise exception 'the freshman Kim row was disturbed'; end if;

  -- Print View repointed on exactly this row; nothing else moved.
  if (select count(*) from rosters where id = rid
        and pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf') <> 1 then
    raise exception 'pdf_storage_path not updated'; end if;
  if (select count(*) from rosters where year = '2026-27'
        and pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf') <> 1 then
    raise exception 'more than one row points at r5'; end if;
  if (select count(*) from rosters where year = '2026-27'
        and coalesce(schedule_pdf_storage_path, '') <> 'documents/schedules/2026-27-r3.pdf') <> 0 then
    raise exception 'the shared schedule PDF pointer was disturbed'; end if;
end $$;

commit;

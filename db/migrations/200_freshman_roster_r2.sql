-- 200_freshman_roster_r2.sql
--
-- Freshman roster update from the coaching staff's revised PDF
-- ("2026_McNeil_Freshman_Football_Roster.xlsm - Freshman Roster (1).pdf"),
-- given to Claude by Jeremy 2026-09-17. Roster goes 49 -> 50 players and the
-- Print View PDF is repointed at the new export.
--
-- ── JEREMY SAW ONE CHANGE. THE DIFF FOUND FOUR. ──
-- Jeremy: "please add #19 Khalil Miller to the freshman roster ... at a glance,
-- that was the one change I saw." The live PDF (freshman-2026.pdf, 49 players,
-- 2 pages) and the new one (50 players, 1 page) were parsed by jersey and by
-- name and diffed programmatically, per 168's rule of parsing by value rather
-- than trusting a glance. Every other (jersey, name) pair is identical.
--
--   1. #19 Khalil Miller            NEW          (what Jeremy asked for)
--   2. Quinten Spurlock   #30 -> #35             (renumbered)
--   3. Adam Zayad         #74 -> #56             (swapped with 4)
--   4. Andy Fernandez     #56 -> #74             (swapped with 3)
--
-- ⚠️ 3 AND 4 ARE A CLEAN SWAP OF TWO PLAYERS' NUMBERS, WHICH IS EXACTLY WHAT A
-- SPREADSHEET SLIP LOOKS LIKE AS WELL AS WHAT A REAL REASSIGNMENT LOOKS LIKE.
-- Applied anyway, because the standing rule (166/168/186) is that the page and
-- the printed roster come from the coaches' artefact and may not disagree with
-- it or each other; 186 refuses to ship a PDF the DB does not match. Flagged to
-- Jeremy in the same message that reported this migration. If the coaches say
-- the swap was a mistake, the fix is a corrected PDF plus a one-migration
-- reverse swap, not a quiet DB edit that leaves the poster wrong.
--
-- ── THE PDF IS THE OTHER HALF, DONE IN THE SAME SITTING (178/186) ──
-- Uploaded as `documents/rosters/freshman-2026-r2.pdf` -- NEW FILENAME, NOT AN
-- OVERWRITE (158's cache rule: Storage serves no-cache, Next falls back to a
-- 31-day TTL, a replaced object can serve stale bytes for a month). Upload with
-- the key in the `apikey` header. The original `freshman-2026.pdf` stays in the
-- bucket, unreferenced, for the rollback. Served object verified sha256-identical
-- to the local file before this was written. Local copy pinned at
-- `MavericksWebsite/roster_pdf/source/freshman-2026-r2-source.pdf` (gitignored).
--
-- ── SHAPE ──
-- 168's conventions hold: jersey as plain integer text, first token = first
-- name, sort_order dense 1..N in jersey order (re-densified below because #19
-- shifts everyone after it), no position/grade/height/weight because the staff's
-- PDF has none, straight apostrophes. Only the Green row; Blue stays empty (148).
--
-- DB-ONLY, NO DEPLOY. Roster pages and the Print View link read at request time.
--
-- Rollback: 200_rollback.sql

begin;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year='2026-27' and team_level='freshman' and team_designation='Green' and active
     and pdf_storage_path = 'documents/rosters/freshman-2026.pdf';
  if rid is null then raise exception 'freshman Green roster not found on freshman-2026.pdf (already applied?)'; end if;

  select count(*) into n from players where roster_id = rid;
  if n <> 49 then raise exception 'expected 49 freshman players before this migration, found %', n; end if;

  -- The four rows this migration touches must be exactly where the OLD pdf put them.
  if (select count(*) from players where roster_id=rid and jersey_number='19') <> 0 then
    raise exception '#19 already taken on the freshman roster'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='30' and first_name='Quinten' and last_name='Spurlock') <> 1 then
    raise exception 'Quinten Spurlock is not #30'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='35') <> 0 then
    raise exception '#35 already taken on the freshman roster'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='74' and first_name='Adam' and last_name='Zayad') <> 1 then
    raise exception 'Adam Zayad is not #74'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='56' and first_name='Andy' and last_name='Fernandez') <> 1 then
    raise exception 'Andy Fernandez is not #56'; end if;
end $$;

-- 1. New player.
insert into players (roster_id, jersey_number, first_name, last_name, sort_order, active)
select r.id, '19', 'Khalil', 'Miller', 0, true
  from rosters r
 where r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green';

-- 2. Spurlock renumbered.
update players p set jersey_number = '35', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number = '30' and p.first_name='Quinten' and p.last_name='Spurlock';

-- 3 + 4. Zayad / Fernandez swap, via a placeholder so neither step collides.
update players p set jersey_number = 'SWAP', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number = '74' and p.first_name='Adam' and p.last_name='Zayad';
update players p set jersey_number = '74', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number = '56' and p.first_name='Andy' and p.last_name='Fernandez';
update players p set jersey_number = '56', updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
   and p.jersey_number = 'SWAP';

-- Re-densify sort_order in jersey order (168 decision 3).
with ranked as (
  select p.id, row_number() over (order by (p.jersey_number)::int) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='freshman' and r.team_designation='Green'
)
update players p set sort_order = ranked.rn, updated_at = now()
  from ranked where ranked.id = p.id and p.sort_order is distinct from ranked.rn;

-- The other half: Print View to the r2 export.
update rosters
   set pdf_storage_path = 'documents/rosters/freshman-2026-r2.pdf',
       source_note = 'Freshman roster provided by the McNeil coaching staff, received 2026-08-26; revised export received 2026-09-17 (#19 Miller added, #35 Spurlock, #56 Zayad / #74 Fernandez)',
       updated_at = now()
 where year='2026-27' and team_level='freshman' and team_designation='Green';

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year='2026-27' and team_level='freshman' and team_designation='Green';

  select count(*) into n from players where roster_id = rid;
  if n <> 50 then raise exception 'expected 50 freshman players, found %', n; end if;

  -- The four changed rows read exactly as the r2 PDF prints them.
  if (select count(*) from players where roster_id=rid and jersey_number='19' and first_name='Khalil' and last_name='Miller' and active) <> 1 then
    raise exception 'Khalil Miller #19 missing'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='35' and first_name='Quinten' and last_name='Spurlock') <> 1 then
    raise exception 'Spurlock is not #35'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='56' and first_name='Adam' and last_name='Zayad') <> 1 then
    raise exception 'Zayad is not #56'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number='74' and first_name='Andy' and last_name='Fernandez') <> 1 then
    raise exception 'Fernandez is not #74'; end if;
  if (select count(*) from players where roster_id=rid and jersey_number in ('30','SWAP')) <> 0 then
    raise exception 'a stale #30 or placeholder jersey survived'; end if;

  -- No duplicate jerseys, all plain integers.
  select count(*) into n from (select jersey_number from players where roster_id=rid group by 1 having count(*)>1) d;
  if n <> 0 then raise exception '% duplicate freshman jersey number(s)', n; end if;
  select count(*) into n from players where roster_id = rid and jersey_number !~ '^[0-9]+$';
  if n <> 0 then raise exception '% freshman jerseys are not plain integers', n; end if;

  -- sort_order dense 1..50 in jersey order (168's invariant, restated).
  if (select count(distinct sort_order) from players where roster_id=rid) <> 50
     or (select min(sort_order) from players where roster_id=rid) <> 1
     or (select max(sort_order) from players where roster_id=rid) <> 50 then
    raise exception 'freshman sort_order is not a dense 1..50 sequence';
  end if;
  select count(*) into n from (
    select sort_order, row_number() over (order by (jersey_number)::int) as by_jersey
    from players where roster_id = rid
  ) t where t.sort_order <> t.by_jersey;
  if n <> 0 then raise exception '% freshman rows are not in jersey order', n; end if;

  -- Print View repointed on the Green row only; JV/varsity/Blue and the shared schedule PDF untouched.
  if (select pdf_storage_path from rosters where id=rid) <> 'documents/rosters/freshman-2026-r2.pdf' then
    raise exception 'freshman Print View was not repointed'; end if;
  select count(*) into n from rosters where year='2026-27' and pdf_storage_path = 'documents/rosters/freshman-2026-r2.pdf';
  if n <> 1 then raise exception '% rows point at freshman r2', n; end if;
  select count(*) into n from rosters where year='2026-27' and team_level='jv' and pdf_storage_path='documents/rosters/jv-2026.pdf';
  if n <> 1 then raise exception 'JV Print View disturbed'; end if;
  select count(*) into n from rosters where year='2026-27' and team_level='varsity' and pdf_storage_path='documents/rosters/varsity-2026-r4.pdf';
  if n <> 1 then raise exception 'varsity Print View disturbed'; end if;
  select count(*) into n from rosters
   where year = '2026-27' and coalesce(schedule_pdf_storage_path, '') <> 'documents/schedules/2026-27-r3.pdf';
  if n <> 0 then raise exception 'the shared schedule PDF pointer was disturbed on % row(s)', n; end if;

  -- Blue still empty.
  select count(*) into n from players p join rosters r on r.id=p.roster_id
   where r.year='2026-27' and r.team_level='freshman' and r.team_designation='Blue';
  if n <> 0 then raise exception 'Blue roster gained % player(s)', n; end if;
end $$;

commit;

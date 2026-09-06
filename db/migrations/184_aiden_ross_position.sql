-- 184_aiden_ross_position.sql
--
-- Sets POSITION = 'OL' on varsity #67 Aiden Ross. 183 deliberately left it null
-- because Jeremy supplied only number, name and grade, and copying a position
-- across team levels is a guess. Asked and answered the same session, 2026-09-06:
-- use the OL the coaching staff's own workbook carries for him.
--
-- ── THE SOURCE IS THE COACHES' WORKBOOK, NOT THE WEBSITE ──
-- `roster_pdf/source/Varsity McNeil Roster 2026.xlsx` has a JV sheet as well as
-- the varsity one, and its JV block reads `Aiden Robert Ross | OL | 11`. Class 11
-- matches the junior Jeremy gave, so it is the same player, and `/roster/jv`
-- already publishes OL for him (seeded by 166 from that file). This is the club
-- republishing a position the staff supplied, not inventing one.
--
-- ⚠️ IT IS STILL A CROSS-LEVEL READ. If the varsity staff play him somewhere
-- else, this is where that error entered. `183` records the alternative that was
-- declined (leave it as an em-dash) so reverting is a decision, not a rediscovery.
--
-- 🚫 Do NOT let this become a precedent for backfilling the other empty Position
-- and Grade cells. Those are empty because nobody supplied them; this one had a
-- named source for this specific player. The em-dashes stay (Jeremy 2026-08-26).
--
-- The workbook's varsity sheet gains the same 'OL' in the same sitting, so the
-- print PDF and the page cannot disagree -- see 186.
--
-- DB-ONLY, NO DEPLOY. /roster/* renders on demand.
--
-- Rollback: 184_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross'
     and p.position is null;
  if n <> 1 then raise exception 'varsity #67 Aiden Ross not found with a null position (found %)', n; end if;

  -- The JV row this position is taken from must actually still say OL.
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv'
     and p.first_name = 'Aiden' and p.last_name = 'Robert Ross' and p.position = 'OL';
  if n <> 1 then raise exception 'the JV source row no longer reads OL; do not copy it'; end if;
end $$;

update players p
   set position = 'OL', updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
   and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross';

do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.jersey_number = '67' and p.position = 'OL';
  if n <> 1 then raise exception 'position did not take'; end if;

  -- Nothing else on the varsity roster gained a position. 45 of the 46 rows had
  -- one before 183; the em-dash rule means that count must not creep.
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.position is not null;
  if n <> 46 then raise exception 'expected 46 varsity rows with a position, found %', n; end if;
end $$;

commit;

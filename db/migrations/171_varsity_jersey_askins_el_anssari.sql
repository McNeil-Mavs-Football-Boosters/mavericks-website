-- 171_varsity_jersey_askins_el_anssari.sql
--
-- Two varsity jersey corrections, from Jeremy watching the Aug 28 game:
-- Aymane El Anssari wore 10 and Ford Askins wore 9.
--
--   Ford Askins        '9/10' -> '9'
--   Aymane El Anssari  '29'   -> '10'
--
-- ── WHY '9/10' WAS WRONG, WHICH IS THE POINT OF THIS MIGRATION ──
--
-- The slash is NOT a "we aren't sure which number he wears". Jeremy established
-- 2026-08-28 that it means a player has DIFFERENT HOME AND AWAY JERSEYS, and
-- both numbers are really his. Ford is not one of those: he wears 9, and the
-- 10 in his cell was Aymane's number sitting in the wrong player's row.
--
-- ⚠️ SO DO NOT "TIDY UP" THE FOUR REMAINING SLASHES. '5/2' (Zylen Hall),
-- '8/18' (Kaden Kearney), '64/65' (Jace Hicks) and '84/80' (Amery Schoepflin)
-- are correct data and must stay. A future reader who finds this migration
-- collapsing one slashed number could easily assume slashes are a data-quality
-- problem to be swept. They are a real thing about real jerseys.
--
-- ── SORT ORDER IS RECOMPUTED, NOT HAND-PATCHED ──
--
-- 159 established that varsity sort_order is jersey ascending, dense from 1.
-- Aymane moving 29 -> 10 moves him sixteen places up the page, so sixteen other
-- players shift by one. Rather than write seventeen literal UPDATEs, the order
-- is recomputed from the data by the LEADING NUMBER of jersey_number, which is
-- the same key the printed roster sorts on ('8/18' sorts as 8, '84/80' as 84).
-- Ford at 9 keeps his slot; only Aymane actually moves.
--
-- ── THE PDF IS PART OF THIS CHANGE, NOT A FOLLOW-UP ──
--
-- The Print View PDF is generated from the coaches' workbook, so the workbook
-- was corrected and the PDF regenerated. It goes to a NEW FILENAME,
-- varsity-2026-r3.pdf, per the house rule 158 set: Storage serves no-cache but
-- next.config.ts sets minimumCacheTTL to 31 days, and replacing an object at a
-- live path has served stale bytes before. r2 is left in the bucket, unreferenced.
--
-- ⚠️ The PDF keeps the coaches' TWO-BLOCK layout -- it is the artefact people
-- tape to a wall. Aymane crossing from the right block to the left rebalanced
-- it from 22/23 to 23/22, which is expected. Do NOT regenerate it as one flat
-- column to match the web page; 159 and 166 both say so.
--
-- Uploaded and verified public before this migration was written:
-- documents/rosters/varsity-2026-r3.pdf, 120015 bytes, reads 9 Ford Askins and
-- 10 Aymane El Anssari, and no longer contains '29' or '9/10'.
--
-- DB-ONLY, NO DEPLOY. /roster/varsity renders on demand.
--
-- Rollback: 171_rollback.sql

begin;

-- Guard: the roster must still look the way 157/158 left it, and both players
-- must still hold the numbers we think we are changing. Stop rather than
-- silently no-op if someone got here first.
do $$
declare n int;
begin
  select count(*) into n
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.active;
  if n <> 45 then
    raise exception 'expected 45 active varsity players, found %', n;
  end if;

  select count(*) into n
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and ((p.first_name = 'Ford'   and p.last_name = 'Askins'     and p.jersey_number = '9/10')
       or (p.first_name = 'Aymane' and p.last_name = 'El Anssari' and p.jersey_number = '29'));
  if n <> 2 then
    raise exception 'Askins 9/10 + El Anssari 29 not both present (found %)', n;
  end if;
end $$;

update players p
   set jersey_number = '9', updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and p.first_name = 'Ford' and p.last_name = 'Askins';

update players p
   set jersey_number = '10', updated_at = now()
  from rosters r
 where r.id = p.roster_id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and p.first_name = 'Aymane' and p.last_name = 'El Anssari';

-- Recompute sort_order: jersey ascending by leading number, dense from 1.
with ranked as (
  select p.id,
         row_number() over (
           order by (regexp_match(p.jersey_number, '^\d+'))[1]::int, p.last_name
         ) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.active
)
update players p
   set sort_order = ranked.rn, updated_at = now()
  from ranked
 where p.id = ranked.id and p.sort_order is distinct from ranked.rn;

update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r3.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

-- Verify: the two numbers landed, the four real dual numbers survived, nobody
-- shares a number, and sort_order is still a dense 1..45 in jersey order.
do $$
declare n int; bad int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='varsity'
     and ((p.first_name='Ford' and p.jersey_number='9')
       or (p.first_name='Aymane' and p.jersey_number='10'));
  if n <> 2 then raise exception 'jersey update did not take (%)', n; end if;

  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='varsity' and p.jersey_number like '%/%';
  if n <> 4 then raise exception 'expected 4 dual numbers to remain, found %', n; end if;

  select count(*) into bad from (
    select (regexp_match(p.jersey_number,'^\d+'))[1]::int k
      from players p join rosters r on r.id=p.roster_id
     where r.year='2026-27' and r.team_level='varsity' and p.active
     group by 1 having count(*) > 1) d;
  if bad <> 0 then raise exception '% duplicate jersey numbers', bad; end if;

  select count(*) into bad from (
    select p.sort_order,
           row_number() over (order by (regexp_match(p.jersey_number,'^\d+'))[1]::int) rn
      from players p join rosters r on r.id=p.roster_id
     where r.year='2026-27' and r.team_level='varsity'
       and r.team_designation is null and p.active) d
   where d.sort_order <> d.rn;
  if bad <> 0 then raise exception 'sort_order not dense jersey order (% rows off)', bad; end if;

  select count(*) into n from rosters
   where year='2026-27' and team_level='varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r3.pdf';
  if n <> 1 then raise exception 'pdf_storage_path not updated'; end if;
end $$;

commit;

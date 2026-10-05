-- 228_varsity_roster_r6_name_fixes.sql
--
-- Two name corrections on the 2026-27 varsity roster, page AND print PDF.
-- Raised by Shannon Schoepflin 2026-10-05, relayed by Jeremy:
--
--   #30     Quamere Southernland -> Quamere Sutherland  (his mom's spelling;
--           "Southernland" came from the coaches' export)
--   #84/80  Amery A. Schoepflin  -> Amery Schoepflin    (the middle initial is
--           not "A"; Shannon is his mom; dropped entirely)
--
-- ⚠️ This retires 157's one hand-specified name-split exception ('Amery A.' /
-- 'Schoepflin'): first_name is now plain 'Amery'. Last season's JV-era rows
-- (2025-26: "Quamera Sutherland", "Amery Schoepflin") are history and untouched.
--
-- PDF half, same sitting (176/186 rule): workbook cells F6 and F25 edited
-- (r5 workbook + PDF archived under roster_pdf/source/archive/), regenerated,
-- diffed against r5 (exactly those two lines changed), uploaded as
-- documents/rosters/varsity-2026-r6.pdf (new filename per 158), sha256 round
-- trip identical. r5 stays in the bucket for the rollback.
--
-- DB-ONLY, NO DEPLOY. Rollback: 228_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and ((pl.jersey_number = '30' and pl.first_name = 'Quamere' and pl.last_name = 'Southernland')
       or (pl.jersey_number = '84/80' and pl.first_name = 'Amery A.' and pl.last_name = 'Schoepflin'));
  if n <> 2 then raise exception 'expected the 2 rows as misspelled, found % (already applied?)', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity'
     and pdf_storage_path = 'documents/rosters/varsity-2026-r5.pdf';
  if n <> 1 then raise exception 'varsity roster not on r5 (%)', n; end if;
end $$;

update players pl set last_name = 'Sutherland', updated_at = now()
  from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '30' and pl.last_name = 'Southernland';

update players pl set first_name = 'Amery', updated_at = now()
  from rosters r
 where r.id = pl.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and pl.jersey_number = '84/80' and pl.first_name = 'Amery A.';

update rosters set pdf_storage_path = 'documents/rosters/varsity-2026-r6.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity';

do $$
declare n int;
begin
  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and (pl.last_name = 'Southernland' or pl.first_name like '%.%');
  if n <> 0 then raise exception 'a misspelling survived (%)', n; end if;

  select count(*) into n from players pl join rosters r on r.id = pl.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 49 then raise exception 'varsity roster is % rows, expected 49', n; end if;
end $$;

commit;

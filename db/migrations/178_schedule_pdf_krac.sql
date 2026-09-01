-- 178_schedule_pdf_krac.sql
--
-- Point the Print View at the schedule PDF that has the Sep. 4 home opener at KRAC.
--
--   documents/schedules/2026-27-r2.pdf  ->  documents/schedules/2026-27-r3.pdf
--
-- Pairs with migration 177, which moved the game in `games`. **Applied in the same
-- sitting on purpose.** Yesterday's Senior Night miss (migration 176) was twelve
-- days of the database and this PDF disagreeing, because 151 changed the data and
-- nothing changed the artefact. Splitting 177 from 178 would reproduce it exactly,
-- three days before the game.
--
-- The PDF was regenerated from the school's ORIGINAL with 19 audited edits, not
-- edited from r2, so it stays one generation deep. New filename per 158's rule
-- (minimumCacheTTL is 31 days). r2 and the original 2026-27.pdf both stay in the
-- bucket, unreferenced.
--
-- ⚠️ ALL FOUR roster rows carry schedule_pdf_storage_path, including the hidden
-- freshman Blue one. Same reasoning as 176.
--
-- DB-ONLY, NO CODE DEPLOY. The PDF was uploaded and verified byte-identical before
-- this ran.
--
-- Rollback: 178_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r2.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r2, found %', n; end if;

  -- Do not ship a PDF that says KRAC unless the data says KRAC.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'varsity'
     and g.game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and v.name = 'Kelly Reeves Athletic Complex';
  if n <> 1 then
    raise exception 'Sep 4 varsity is not at Kelly Reeves in games; run 177 first';
  end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r3.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r3.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r3, found %', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path like '%2026-27.pdf'
      or (year = '2026-27' and schedule_pdf_storage_path like '%-r2.pdf');
  if n <> 0 then raise exception '% rows still point at an older PDF', n; end if;
end $$;

commit;

-- 176_schedule_pdf_senior_night.sql
--
-- Point the Print View at a schedule PDF that has Senior Night on the RIGHT DATE.
--
--   documents/schedules/2026-27.pdf  ->  documents/schedules/2026-27-r2.pdf
--
-- ── WHAT WAS WRONG, AND FOR HOW LONG ──
-- The legend at the foot of the school's schedule reads "^Senior Night", and the
-- caret sat on the **Sep. 4 Lake Belton** row, because that is where the school
-- put Senior Night in its April 2026 export. Jeremy moved Senior Night to
-- **Oct. 9 vs Stony Point** on 2026-08-19 in migration 151.
--
-- 151 was correct and it was labelled "DB-only, no deploy" -- which was true for
-- every surface that READS the database. It was not true for this PDF, which is a
-- static artefact generated once and uploaded. **So from 2026-08-19 to 2026-08-31
-- the site said Oct 9 and the schedule parents actually download and print said
-- Sep 4.** Found by Jeremy, not by us. Twelve days.
--
-- 🚨 THIS IS THE THIRD TIME THE SAME CLASS OF BUG HAS BITTEN IN TWO WEEKS:
--   * the freshman/JV Google Form kept the horseshoe drop-off and "still
--     confirming the time" after all four code surfaces were corrected (8/29),
--   * the varsity roster PDF kept Askins at 9/10 until the workbook behind it was
--     edited too (migration 171, 8/29),
--   * and now the schedule PDF kept Senior Night on Sep 4 (this migration).
-- **"DB-only, no deploy" means no CODE deploy. It never meant no other work.**
-- Before writing that phrase again, ask which non-reading artefacts carry the same
-- fact: the two PDFs in `MavericksWebsite/schedule_pdf/` and `roster_pdf/`, the
-- Google Forms, and the Apps Scripts. None of them are reachable from a migration.
--
-- ── HOW THE PDF WAS FIXED ──
-- `scripts/patch-schedule-pdf.py` gained two edits (Sep. 4 drops the caret, Oct. 9
-- gains it) and was re-run from the school's original, so this file is the April
-- export plus eighteen audited cells rather than an edit of an edit. The opponent
-- column is CENTRED on 270.58 like the others, so both cells re-centre.
-- The `**` Homecoming marker on Oct. 23 Round Rock was checked at the same time
-- and is correct: 151 moved only Senior Night.
--
-- New filename per 158's rule -- Storage serves no-cache but next.config.ts sets
-- minimumCacheTTL to 31 days, and replacing an object at a live path has served
-- stale bytes before. The old object stays in the bucket, unreferenced.
--
-- ⚠️ ALL FOUR ROSTER ROWS CARRY schedule_pdf_storage_path (varsity, jv, and BOTH
-- freshman rows including the hidden Blue one). The Print View link on every
-- /schedule/games/* page reads it from that level's row, so updating three of four
-- leaves one page serving the wrong PDF. Blue is invisible today but the row still
-- exists; same reasoning as 155 and 170.
--
-- DB-ONLY, NO CODE DEPLOY. The PDF itself was uploaded before this ran.
--
-- Rollback: 176_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27.pdf';
  if n <> 4 then
    raise exception 'expected 4 roster rows on the old schedule PDF, found %', n;
  end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r2.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r2.pdf';
  if n <> 4 then raise exception 'expected 4 rows on the new PDF, found %', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27.pdf';
  if n <> 0 then raise exception '% rows still point at the old PDF', n; end if;

  -- Senior Night must still be Oct 9 in the data this PDF now agrees with.
  -- ⚠️ IT LIVES IN games.notes ON THE VARSITY ROW, not in `events`. A first draft
  -- of this guard looked in `events` and failed the whole migration -- correctly,
  -- since a guard that cannot find the fact it is guarding must not pass. There is
  -- no `occasion` column; `notes` carries 'Senior Night', 'Homecoming' and
  -- 'Scrimmage', and that is the whole vocabulary.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity' and notes = 'Senior Night'
     and (game_date at time zone 'America/Chicago')::date = date '2026-10-09';
  if n <> 1 then
    raise exception 'Senior Night is not the Oct 9 varsity note; do not ship a PDF that says it is';
  end if;

  -- And Homecoming must still be Oct 23, since the ** marker was left untouched.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity' and notes = 'Homecoming'
     and (game_date at time zone 'America/Chicago')::date = date '2026-10-23';
  if n <> 1 then
    raise exception 'Homecoming is not the Oct 23 varsity note, but the PDF still marks Oct 23';
  end if;

  -- Nothing else may claim either occasion, or the PDF's single marker is a lie.
  select count(*) into n from games
   where year = '2026-27' and notes in ('Senior Night', 'Homecoming');
  if n <> 2 then
    raise exception 'expected exactly 2 occasion rows in 2026-27, found %', n;
  end if;
end $$;

commit;

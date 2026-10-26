-- 258_schedule_pdf_r7_oct29.sql
--
-- Print View schedule PDF r6 -> r7. r7 is patch-schedule-pdf.py re-run from the
-- school's original with one more cell (25 total), matching 257 and Coach's
-- Week 13 sheet: JV Oct. 29 6:00 -> 5:30. Freshman Oct. 29 stays 5:00/6:30 (TBA
-- on the sheet). New filename per 158's 31-day cache rule; r6 stays in the
-- bucket for rollback. Guarded on `games` agreeing (178's pattern).
-- Rollback: 258_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r6.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r6, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Westwood High School' and team_level = 'jv'
     and game_date = timestamptz '2026-10-29 17:30 America/Chicago';
  if n <> 1 then raise exception 'JV Oct 29 is not 5:30 in games; run 257 first'; end if;

  select count(*) into n from storage.objects
   where bucket_id = 'documents' and name = 'schedules/2026-27-r7.pdf';
  if n <> 1 then raise exception 'schedules/2026-27-r7.pdf not uploaded'; end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r7.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r7.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r7, found %', n; end if;
end $$;

commit;

-- 260_schedule_pdf_r8_freshman_oct29.sql
--
-- Print View schedule PDF r7 -> r8. r8 is patch-schedule-pdf.py re-run from the
-- school's original with one more cell (26 total), matching 259: freshman Oct. 29
-- 5:00/6:30 -> 5:30 (Coach announced it after the Week 13 sheet said TBA). New filename per 158's 31-day cache rule; r7 stays in the
-- bucket for rollback. Guarded on `games` agreeing (178's pattern).
-- Rollback: 260_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r7.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r7, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Westwood High School' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-10-29 17:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Oct 29 is not 5:30 in games; run 259 first'; end if;

  select count(*) into n from storage.objects
   where bucket_id = 'documents' and name = 'schedules/2026-27-r8.pdf';
  if n <> 1 then raise exception 'schedules/2026-27-r8.pdf not uploaded'; end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r8.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r8.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r8, found %', n; end if;
end $$;

commit;

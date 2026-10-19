-- 250_schedule_pdf_r6_oct22.sql
--
-- Print View schedule PDF r5 -> r6. r6 is patch-schedule-pdf.py re-run from the
-- school's original with two more cells (24 total), matching 249 and Coach's
-- Week 12 sheet: JV Oct. 22 6:00 -> 5:30, freshman Oct. 22 5:00/6:30 -> 5:30.
-- New filename per 158's 31-day cache rule; r5 stays in the bucket for rollback.
-- Guarded on `games` agreeing (178's pattern). Rollback: 250_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r5.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r5, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Round Rock High School'
     and game_date = timestamptz '2026-10-22 17:30 America/Chicago'
     and (team_level = 'jv' or (team_level = 'freshman' and team_designation = 'Green'));
  if n <> 2 then raise exception 'JV/freshman Oct 22 are not 5:30 in games; run 249 first'; end if;

  select count(*) into n from storage.objects
   where bucket_id = 'documents' and name = 'schedules/2026-27-r6.pdf';
  if n <> 1 then raise exception 'schedules/2026-27-r6.pdf not uploaded'; end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r6.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r6.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r6, found %', n; end if;
end $$;

commit;

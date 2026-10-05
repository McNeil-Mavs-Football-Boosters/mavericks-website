-- 227_schedule_pdf_r5_oct8.sql
--
-- Print View schedule PDF r4 -> r5. r5 is patch-schedule-pdf.py re-run from the
-- school's original with one more cell (22 total), matching 225 and Coach's
-- Week 10 graphic: freshman Oct. 8 5:00/6:30 -> 5:30. New filename per 158's
-- 31-day cache rule; r4 stays in the bucket for rollback.
-- Guarded on `games` agreeing (178's pattern). Rollback: 227_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r4.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r4, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-10-08 17:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Green Oct 8 is not 5:30 in games; run 225 first'; end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r5.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r5.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r5, found %', n; end if;
end $$;

commit;

-- 220_schedule_pdf_r4_oct1.sql
--
-- Print View schedule PDF r3 -> r4. r4 is patch-schedule-pdf.py re-run from the
-- school's original with two more cells (21 total), matching 219 and Coach's
-- Week 9 graphic: JV Oct. 1 6:00 -> 5:30, freshman Oct. 1 5:00/6:30 -> 6:30.
-- New filename per 158's 31-day cache rule; r3 stays in the bucket for rollback.
-- Guarded on `games` agreeing (178's pattern). Rollback: 220_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r3.pdf';
  if n <> 4 then raise exception 'expected 4 roster rows on r3, found %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-10-01 17:30 America/Chicago';
  if n <> 1 then raise exception 'JV Oct 1 is not 5:30 in games; run 219 first'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-10-01 18:30 America/Chicago';
  if n <> 1 then raise exception 'freshman Green Oct 1 is not 6:30 in games'; end if;
end $$;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r4.pdf', updated_at = now()
 where year = '2026-27';

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r4.pdf';
  if n <> 4 then raise exception 'expected 4 rows on r4, found %', n; end if;
end $$;

commit;

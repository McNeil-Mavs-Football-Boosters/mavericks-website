-- 178_rollback.sql — points the Print View back at r2 (Senior Night correct,
-- but the Sep 4 home opener still shows Dragon Stadium). Roll back 177 with it.

begin;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r2.pdf', updated_at = now()
 where year = '2026-27';

commit;

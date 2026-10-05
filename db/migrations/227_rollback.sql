-- 227_rollback.sql -- Print View back to r4.
begin;
update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27-r4.pdf', updated_at = now()
 where year = '2026-27';
commit;

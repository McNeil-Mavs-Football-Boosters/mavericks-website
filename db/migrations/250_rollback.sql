-- 250_rollback.sql
begin;
update rosters set schedule_pdf_storage_path = 'documents/schedules/2026-27-r5.pdf', updated_at = now()
 where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r6.pdf';
commit;

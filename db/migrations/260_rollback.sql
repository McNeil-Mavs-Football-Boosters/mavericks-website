-- 260_rollback.sql
begin;
update rosters set schedule_pdf_storage_path = 'documents/schedules/2026-27-r7.pdf', updated_at = now()
 where year = '2026-27' and schedule_pdf_storage_path = 'documents/schedules/2026-27-r8.pdf';
commit;

-- 176_rollback.sql — points the Print View back at the pre-Senior-Night-fix PDF.
-- ⚠️ That file says Senior Night is Sep 4, which is WRONG. Roll back only if the
-- r2 upload itself is bad, and fix it forward rather than leaving this in place.

begin;

update rosters
   set schedule_pdf_storage_path = 'documents/schedules/2026-27.pdf', updated_at = now()
 where year = '2026-27';

commit;

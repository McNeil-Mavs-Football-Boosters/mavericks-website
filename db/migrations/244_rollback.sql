-- 244_rollback.sql
-- Removes the Senior Year Checklist row. Leaves the PDF in the documents bucket.

begin;

delete from resource_links where label = 'Senior Year Checklist';

commit;

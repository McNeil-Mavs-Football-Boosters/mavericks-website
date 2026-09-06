-- 186_rollback.sql
--
-- Points varsity Print View back at varsity-2026-r3.pdf, which is still in the
-- bucket (158's rule: retired revisions are left in place, unreferenced).
--
-- ⚠️ r3 has 45 players and no Aiden Ross. Roll this back only alongside 184 and
-- 183, or the printed roster and /roster/varsity will disagree -- the 176 bug.
-- The workbook on Jeremy's disk also needs its row 19 removed to regenerate r3.

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf';
  if n <> 1 then raise exception 'varsity roster is not on r4 (not 186 to roll back?)'; end if;
end $$;

update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r3.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

commit;

-- 244_resources_senior_checklist.sql
--
-- Posts the Senior Year Checklist to /resources under Registration & Forms.
-- Jeremy committed to it at the 2026-10-12 board meeting (Debby's idea: senior
-- parents had no list of what senior year asks of them). Built by
-- MavericksWebsite/senior_checklist/build_senior_checklist.py, outside this repo
-- (binaries and one-off tooling stay out, same as the BOY checklist, 105).
--
-- GENERIC ON PURPOSE: no dates, times or names, so the label is NOT
-- year-stamped and the same object can stay up next season. A content change
-- uploads a new object (-r2) and repoints this row; never overwrite in place
-- (31-day image/document cache, 158's rule).
--
-- Object: documents/checklists/senior-checklist.pdf, 2 pages,
-- sha256 d64b0a6a...22405511, round trip verified 2026-10-12.
--
-- sort_order 3: after the BOY checklist (0) and Rank One (1), before the meal
-- program (4). Slot 2 is the inactive UIL row, so no active tie.
-- No ?download= param, matching 105. DB-ONLY, NO DEPLOY. Rollback: 244_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from resource_links where label = 'Senior Year Checklist';
  if n <> 0 then raise exception 'Senior Year Checklist row already exists (%)', n; end if;
end $$;

insert into resource_links (section, sort_order, label, url, description, icon_hint, active)
values (
  'registration_forms',
  3,
  'Senior Year Checklist',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/documents/checklists/senior-checklist.pdf',
  'For senior football families: Media Day, the Senior Night form, team dinners and more, in the order they come up.',
  'pdf',
  true
);

commit;

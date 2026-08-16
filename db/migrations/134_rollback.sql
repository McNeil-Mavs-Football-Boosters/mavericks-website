-- 134_rollback.sql — drops the venues mechanism.
--
-- ⚠️ NOT symmetric: the forward migration NULLs events.location_url wherever a
-- venue was attached, and this cannot put those URLs back — they were all the
-- McNeil / Phil's / Morningside address links that the venue rows now carry.
-- If you roll this back, re-run the relevant parts of migrations 048/059/087/108
-- to restore them, or the events lose their directions links entirely.

begin;

alter table games  drop column if exists venue_id;
alter table events drop column if exists venue_id;

drop table if exists venues;

commit;

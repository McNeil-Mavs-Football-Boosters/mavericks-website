-- 114_rollback.sql
--
-- Reverses 114. Dropping the column discards every album URL, so if you only
-- want to unpublish ONE album, do NOT run this — just null that row:
--   update events set photos_url = null where slug = '<slug>';

begin;

delete from resource_links where label = 'Event Photos';

alter table events
  drop column if exists photos_url;

commit;

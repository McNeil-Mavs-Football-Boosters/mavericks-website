-- 240_tunnel_stampede_close_date_fix.sql
--
-- 239 copied the flyer's "closes Wednesday, October 22". Oct 22, 2026 is a
-- Thursday. Jeremy 2026-10-12 (via Ashley): registration closes WEDNESDAY,
-- OCTOBER 21; the flyer has been updated. Text-only fix to the event
-- description. The flyer image (event-images/tunnel-stampede-2026-flyer.jpg)
-- still shows the old date until the updated flyer is swapped in.
-- DB-ONLY, NO DEPLOY. Rollback: 240_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%closes Wednesday, October 22%';
  if n <> 1 then raise exception 'event not in its 239 state (%)', n; end if;
end $$;

update events
   set description = replace(description, 'closes Wednesday, October 22', 'closes Wednesday, October 21')
 where slug = 'homecoming-tunnel-stampede-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%closes Wednesday, October 21%'
     and description not like '%October 22%';
  if n <> 1 then raise exception 'post-check failed (%)', n; end if;
end $$;

commit;

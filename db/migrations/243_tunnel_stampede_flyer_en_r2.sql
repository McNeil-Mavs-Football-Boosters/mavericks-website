-- 243_tunnel_stampede_flyer_en_r2.sql
--
-- Jeremy 2026-10-12: spell Eventbrite correctly on both flyers. The vendor
-- English flyer said "Eventbright" (and "particpant"); both fixed in place on
-- the vendor image by MavericksWebsite/event_flyers/build_en.py. Spanish was
-- already corrected in 242. New object per the never-overwrite rule:
-- event-images/tunnel-stampede-2026-flyer-en-r2.jpg (sha256 00b5ce3b...bf142882,
-- round trip verified). Old -en.jpg stays in the bucket.
-- DB-ONLY, NO DEPLOY. Rollback: 243_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%tunnel-stampede-2026-flyer-en.jpg)%'
     and description like '%flyer-es-r2.jpg)%';
  if n <> 1 then raise exception 'event not in its 242 state (%)', n; end if;
end $$;

update events
   set description = replace(description, 'tunnel-stampede-2026-flyer-en.jpg)', 'tunnel-stampede-2026-flyer-en-r2.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%flyer-en-r2.jpg)%'
     and description not like '%flyer-en.jpg)%'
     and description like '%flyer-es-r2.jpg)%';
  if n <> 1 then raise exception 'post-check failed (%)', n; end if;
end $$;

commit;

-- 245_tunnel_stampede_flyer_r3.sql
--
-- Jeremy 2026-10-13: the invitation paragraph on both flyers said "Students who
-- will be attending McNeil High School"; now "Students of any feeder school to
-- McNeil High School" (Spanish: "Los estudiantes de cualquier escuela
-- alimentadora de McNeil High School"). Rebuilt by
-- MavericksWebsite/event_flyers/build_en.py / build_es.py from the vendor
-- images in event_flyers/source/; only the paragraph pixels changed vs r2.
-- New objects per the never-overwrite rule (round trip verified):
--   event-images/tunnel-stampede-2026-flyer-en-r3.jpg  sha256 31e3452b...deb58382
--   event-images/tunnel-stampede-2026-flyer-es-r3.jpg  sha256 a497d123...7287542b
-- r2 objects stay in the bucket. The newsletter flyer image is not touched.
-- DB-ONLY, NO DEPLOY. Rollback: 245_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%tunnel-stampede-2026-flyer-en-r2.jpg)%'
     and description like '%tunnel-stampede-2026-flyer-es-r2.jpg)%';
  if n <> 1 then raise exception 'event not in its 243 state (%)', n; end if;
end $$;

update events
   set description = replace(replace(description,
         'tunnel-stampede-2026-flyer-en-r2.jpg)', 'tunnel-stampede-2026-flyer-en-r3.jpg)'),
         'tunnel-stampede-2026-flyer-es-r2.jpg)', 'tunnel-stampede-2026-flyer-es-r3.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%flyer-en-r3.jpg)%'
     and description like '%flyer-es-r3.jpg)%'
     and description not like '%-r2.jpg)%';
  if n <> 1 then raise exception 'post-check failed (%)', n; end if;
end $$;

commit;

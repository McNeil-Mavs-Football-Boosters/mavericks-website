-- 242_tunnel_stampede_flyer_es_r2.sql
--
-- Jeremy 2026-10-12: the Spanish flyer from 241 was mistranslated and badly
-- formatted. Problems in the vendor file: the invitation paragraph was broken
-- mid-sentence ("competira los estudiantes queasistirán ... secundari a"),
-- "matriculados" (enrolled) where the English says registered, the event named
-- four different ways (bienvenida / regreso a casa / El Stampede / Homecoming
-- Tunnel Stampede), "Octubre" capitalised, tú/usted mixed, uneven type sizes.
-- Rebuilt on the English layout with corrected Spanish; logo, QR, URLs and the
-- Eventbrite listing title kept as pixels. Also spells Eventbrite correctly
-- (both vendor flyers say "Eventbright").
-- New object per the never-overwrite rule: event-images/tunnel-stampede-2026-flyer-es-r2.jpg
-- (sha256 b9638e5d...089a, round trip verified). The old -es.jpg stays in the bucket.
-- DB-ONLY, NO DEPLOY. Rollback: 242_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%tunnel-stampede-2026-flyer-es.jpg)%';
  if n <> 1 then raise exception 'event not in its 241 state (%)', n; end if;
end $$;

update events
   set description = replace(description, 'tunnel-stampede-2026-flyer-es.jpg)', 'tunnel-stampede-2026-flyer-es-r2.jpg)')
 where slug = 'homecoming-tunnel-stampede-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%flyer-es-r2.jpg)%'
     and description not like '%flyer-es.jpg)%'
     and description like '%flyer-en.jpg)%';
  if n <> 1 then raise exception 'post-check failed (%)', n; end if;
end $$;

commit;

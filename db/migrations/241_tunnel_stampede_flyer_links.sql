-- 241_tunnel_stampede_flyer_links.sql
--
-- Jeremy 2026-10-12 sent the UPDATED flyer (closes Wed Oct 21) in English and
-- Spanish and asked for both on the site if no code change is needed. The
-- event description renders through ReactMarkdown + remark-gfm
-- (app/events/[slug]/page.tsx), so two markdown links do it, DB-only.
-- Images uploaded 10/12 to event-images/tunnel-stampede-2026-flyer-{en,es}.jpg
-- (1546x2000 JPEG q85). Not set as cover_image_url (portrait, would be cropped).
-- The old 520px tunnel-stampede-2026-flyer.jpg stays: the sent 10/12 newsletter
-- hotlinks it. Jeremy: do not update the newsletter.
-- DB-ONLY, NO DEPLOY. Rollback: 241_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%closes Wednesday, October 21%'
     and description not like '%flyer-en.jpg%';
  if n <> 1 then raise exception 'event not in its 240 state (%)', n; end if;
end $$;

update events
   set description = description || E'\n\nFlyer: [English](https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/event-images/tunnel-stampede-2026-flyer-en.jpg) | [Español](https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/event-images/tunnel-stampede-2026-flyer-es.jpg)'
 where slug = 'homecoming-tunnel-stampede-2026';

commit;

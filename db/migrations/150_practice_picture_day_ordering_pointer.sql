-- 150_practice_picture_day_ordering_pointer.sql
--
-- Points the Friday Aug 21 picture-day block on all three practice pages at the
-- Picture Day event, where migration 149 put the photographer's ordering button.
-- Jeremy 2026-08-19, alongside 149.
--
-- ⚠️ THE POINTER IS A RELATIVE LINK TO /events/picture-day-2026, NOT THE VENDOR
-- URL. That is the whole design. Migration 133 deliberately kept picture day on
-- the practice pages as well as /events, so a family reading Friday's practice
-- block does not have to know to also check the calendar — which means the
-- ordering link has FOUR candidate homes (three practice bodies + the event).
-- Pasting the vando URL into all four is precisely the duplicated-fact drift
-- this project keeps paying for: when the photographer reissues the gallery,
-- three stale checkouts stay live and nothing signals it. One copy of the URL,
-- in events.signup_url, and everything else links to the page that holds it.
--
-- The bodies render through ReactMarkdown with remark-gfm and styled anchors
-- (app/schedule/practice/[level]/page.tsx), so a markdown link works here — it
-- does NOT on the /events list card or in the ICS feed, which is why 149 needed
-- a real column instead. Different render paths, different affordances.
--
-- Each UPDATE matches the ENTIRE Friday block, header and all, and asserts the
-- body actually changed. Anchoring on "Film during Period 2" alone would be one
-- ambiguous string away from rewriting the Wednesday Period 2 line instead, and
-- the varsity/jv tail ("Film during Period 2") differs from the freshman one
-- ("Film after pictures, time permitting") — so this cannot be one statement.
-- Verified before writing: every anchor below occurs exactly once per body.
--
-- Idempotent: the WHERE clause requires the pointer to be ABSENT, so a re-run
-- is a no-op rather than a second bullet.

begin;

-- Varsity and JV practice together and share the upperclassmen 7:00/8:00 block.
update practice_schedules
set body = replace(
  body,
  E'### Friday, Aug 21 — picture day\n- **7:00 a.m.** — Arrival\n- **8:00 a.m.** — Pictures complete\n- Film during Period 2',
  E'### Friday, Aug 21 — picture day\n- **7:00 a.m.** — Arrival\n- **8:00 a.m.** — Pictures complete\n- Film during Period 2\n- Photo ordering: see the [Picture Day event](/events/picture-day-2026).'
)
where year = '2026-27'
  and team_level in ('varsity', 'jv')
  and body like '%### Friday, Aug 21 — picture day%'
  and body not like '%/events/picture-day-2026%';

-- One freshman team as of migration 148; 8:00/9:15 block, film only if time.
update practice_schedules
set body = replace(
  body,
  E'### Friday, Aug 21 — picture day\n- **8:00 a.m.** — Arrival\n- **9:15 a.m.** — Pictures complete\n- Film after pictures, time permitting',
  E'### Friday, Aug 21 — picture day\n- **8:00 a.m.** — Arrival\n- **9:15 a.m.** — Pictures complete\n- Film after pictures, time permitting\n- Photo ordering: see the [Picture Day event](/events/picture-day-2026).'
)
where year = '2026-27'
  and team_level = 'freshman'
  and body like '%### Friday, Aug 21 — picture day%'
  and body not like '%/events/picture-day-2026%';

-- All three bodies must now carry exactly one pointer. A silently-unmatched
-- replace() returns the body unchanged and reports success, which is how a
-- "done" migration leaves a page with no link on it.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and active
     and (length(body) - length(replace(body, '/events/picture-day-2026', '')))
         / length('/events/picture-day-2026') = 1;
  if n <> 3 then
    raise exception 'expected 3 practice bodies with one ordering pointer, found %', n;
  end if;
end $$;

-- The pointer must sit inside the Friday block, not wherever replace() felt
-- like putting it: it has to fall between the Friday header and Saturday's.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and active
     and position('/events/picture-day-2026' in body) > position(E'### Friday, Aug 21' in body)
     and position('/events/picture-day-2026' in body) < position(E'### Saturday, Aug 22' in body);
  if n <> 3 then
    raise exception 'ordering pointer landed outside the Friday block in % of 3 bodies', 3 - n;
  end if;
end $$;

commit;

-- /schedule/practice/* reads at request time: live with no deploy. Unlike 149,
-- this migration needs no code change at all.

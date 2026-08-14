-- 126_meet_the_mavs_back_to_6pm.sql
--
-- Meet the Mavs is 6:00-8:00 PM after all. Jeremy 2026-08-13, hours after
-- migration 125 moved it to 7:00 PM on the opposite information.
--
-- Net effect: back to what migration 108 originally seeded. 125 + 126 cancel out.
--
-- ── Why this is a FORWARD migration and not just running 125_rollback.sql ──
-- Running the rollback would fix the live database but leave `db/apply_all.sql`
-- — the forward-only bundle — still ending at 125, so anyone rebuilding a
-- database from it would land on 7:00 PM and silently disagree with production.
-- Rollback scripts are for undoing an unshipped mistake in place; once a
-- migration has shipped, reversing it is its own forward step.
--
-- ⚠️ THE TIME HAS NOW FLIPPED TWICE IN ONE DAY on contradicting information from
-- the school. 6:00 PM is ALSO the value migration 108 inherited from the 2025
-- event without independent confirmation, so arriving back here does not mean it
-- has been verified — it means two sources disagreed and the second one won.
-- If it changes again, get it from whoever owns the event and note the source.
--
-- Both places again: the events row AND the Friday block in all three practice
-- bodies. They do not share a source at runtime; the practice text is markdown.

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug='meet-the-mavs-2026'
     and to_char(starts_at at time zone 'America/Chicago','HH24:MI') = '19:00';
  if n <> 1 then
    raise exception 'Expected Meet the Mavs starting 19:00 CT, found % matching row(s)', n;
  end if;
  select count(*) into n from practice_schedules
   where year='2026-27' and body like '%**7:00–8:00 p.m.** — Meet the Mavs%';
  if n <> 3 then
    raise exception 'Expected 3 practice bodies with the 7:00 line, found %', n;
  end if;
end $$;

update events
set starts_at = timestamptz '2026-08-14 18:00 America/Chicago'
where slug = 'meet-the-mavs-2026';

update practice_schedules
set body = replace(
      body,
      '- **7:00–8:00 p.m.** — Meet the Mavs',
      '- **6:00–8:00 p.m.** — Meet the Mavs')
where year = '2026-27'
  and body like '%**7:00–8:00 p.m.** — Meet the Mavs%';

commit;

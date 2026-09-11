-- 194_rollback.sql
--
-- Puts The League spirit night back on Mon Sep 14, 6-8 PM, with 193's exact
-- description. Slug, venue, status and time-of-day were never changed by 194,
-- so only `starts_at`, `ends_at` and `description` are restored.
--
-- Use this only if the 15th falls through and the 14th is genuinely back on --
-- not to "fix" the slug/date mismatch, which is intentional (see 194).

begin;

update events
   set starts_at = timestamptz '2026-09-14 18:00 America/Chicago',
       ends_at   = timestamptz '2026-09-14 20:00 America/Chicago',
       description = 'Join the Mavs for a Spirit Night at The League Kitchen & Tavern (Avery and Parmer) on Monday, September 14, 6:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-the-league-2026-09-14';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'spirit-night-the-league-2026-09-14'
     and starts_at = timestamptz '2026-09-14 18:00 America/Chicago'
     and description like '%Monday, September 14%';
  if n <> 1 then raise exception 'rollback did not restore Mon Sep 14 (%)', n; end if;
end $$;

commit;

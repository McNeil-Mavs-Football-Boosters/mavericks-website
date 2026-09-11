-- 194_spirit_night_league_to_sep15.sql
--
-- The League spirit night moves ONE DAY LATER, Jeremy 2026-09-09:
-- "move the league spirit night from the 14th to the 15th."
--
--   was:  Mon Sep 14, 6:00-8:00 PM
--   now:  Tue Sep 15, 6:00-8:00 PM
--
-- Time (6-8 PM), venue, status and slug are unchanged. Mighty Fine (Sep 30) is
-- not touched and the migration asserts it.
--
-- ⚠️ THE SLUG STILL SAYS `2026-09-14` AND THAT IS DELIBERATE. 192 created this
-- row precisely so there would be a STABLE URL Jeremy hands to John Mark Edwards
-- (Mav Mail) and Debby Mata (social) instead of retyping details in three
-- places. Renaming the slug to `-2026-09-15` would 404 every copy of that link
-- already in someone's mail queue or social post, and there is no redirect layer
-- in this app (`next.config.ts` defines no `redirects()`), so the break would be
-- silent and total. A URL whose date reads one day early is a cosmetic wart; a
-- dead link on the club's own fundraiser is a lost night. **Do not "tidy" the
-- slug later either** — the date in it stopped being a fact the moment this
-- migration ran, and the page itself is the source of truth for when to show up.
--
-- ── THE DAY NAME IS IN THE DESCRIPTION, SO PROSE AND TIMESTAMP MUST MOVE TOGETHER ──
-- 193's copy hardcodes "on Monday, September 14, 6:00-8:00 PM". Only `starts_at`
-- drives the rendered date on the card, the detail page and the ICS feed, so
-- moving the timestamp alone would leave the body text contradicting the heading
-- on the same page. Sep 15 2026 is a **Tuesday** (verified, not assumed). The
-- guards below assert both the new timestamp and the new prose, and that no
-- "September 14" or "Monday" survives anywhere in the description.
--
-- 🚨 THE TWO SENTENCES THAT DO THE WORK ARE PRESERVED VERBATIM AND ASSERTED.
-- "Please mention McNeil Football at the register." is the whole fundraiser (see
-- 193) and "you can buy one there" is an operational promise about merch. This
-- migration is a date change and must not become a quiet re-edit of either.
--
-- ⚠️ TWO THINGS THIS MIGRATION CANNOT DO, BOTH FLAGGED TO JEREMY 2026-09-09:
--   1. **The League has to agree to the new night.** The DB is not the agreement.
--   2. **Other McNeil sports.** The 9/1 board direction was to check other McNeil
--      sports before scheduling a spirit night so families are not split two
--      ways. Sep 15 is a Tuesday and only football's calendar is in this DB.
--
-- Also still open from 193: nobody is assigned to bring the merch table to this
-- event. See `followups.md`.
--
-- DB-ONLY, NO DEPLOY. /events, /events/[slug], the homepage and the ICS feed all
-- read at request time. ⚠️ `/events.ics` is cached an hour — append `?cb=$(date
-- +%s)` when verifying or you will read the pre-change feed.
-- No static artefact carries this date: the schedule PDF and roster PDFs are
-- games and rosters only, and the spirit night is in no Google Form or Apps
-- Script. The one place outside the DB is the 9/8 docs entry, updated alongside.
--
-- Rollback: 194_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'spirit-night-the-league-2026-09-14'
     and status = 'published'
     and starts_at = timestamptz '2026-09-14 18:00 America/Chicago'
     and ends_at   = timestamptz '2026-09-14 20:00 America/Chicago'
     and description like '%Monday, September 14%';
  if n <> 1 then raise exception 'The League spirit night is not on Mon Sep 14 as 192/193 left it (found %)', n; end if;
end $$;

update events
   set starts_at = timestamptz '2026-09-15 18:00 America/Chicago',
       ends_at   = timestamptz '2026-09-15 20:00 America/Chicago',
       description = 'Join the Mavs for a Spirit Night at The League Kitchen & Tavern (Avery and Parmer) on Tuesday, September 15, 6:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-the-league-2026-09-14';

do $$
declare n int;
begin
  -- Moved to Tue Sep 15, still 6-8 PM Central, still published, still at the venue.
  select count(*) into n from events
   where slug = 'spirit-night-the-league-2026-09-14'
     and status = 'published'
     and venue_id is not null
     and starts_at = timestamptz '2026-09-15 18:00 America/Chicago'
     and ends_at   = timestamptz '2026-09-15 20:00 America/Chicago';
  if n <> 1 then raise exception 'The League spirit night did not land on Tue Sep 15 6-8 PM (%)', n; end if;

  -- The prose moved with the timestamp, and nothing stale was left behind.
  select count(*) into n from events
   where slug = 'spirit-night-the-league-2026-09-14'
     and description like '%Tuesday, September 15%'
     and description not like '%September 14%'
     and description not like '%Monday%';
  if n <> 1 then raise exception 'the description still says the old day (%)', n; end if;

  -- Date change only: the two sentences that make the event work are intact.
  select count(*) into n from events
   where slug like 'spirit-night-%'
     and description like '%mention McNeil Football at the register%'
     and description like '%tells them your purchase counts%'
     and description like '%Wear your Mav shirt%'
     and description like '%you can buy one there%';
  if n <> 2 then raise exception 'the mention or shirt line was lost on % of the two', 2 - n; end if;

  -- Mighty Fine is untouched.
  select count(*) into n from events
   where slug = 'spirit-night-mighty-fine-2026-09-30'
     and status = 'published'
     and starts_at = timestamptz '2026-09-30 18:00 America/Chicago'
     and description like '%Wednesday, September 30%';
  if n <> 1 then raise exception 'the Mighty Fine spirit night changed (%)', n; end if;

  -- Nothing else claims Sep 15, so this did not land on top of another event.
  select count(*) into n from events
   where status = 'published'
     and starts_at >= timestamptz '2026-09-15 00:00 America/Chicago'
     and starts_at <  timestamptz '2026-09-16 00:00 America/Chicago';
  if n <> 1 then raise exception 'expected exactly 1 published event on Sep 15, found %', n; end if;
end $$;

commit;

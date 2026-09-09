-- 193_spirit_night_copy.sql
--
-- Two additions to both spirit night descriptions, Jeremy 2026-09-08:
-- "they need to mention mcneil football so say that. plus Please ask people to
--  wear their Mav shirt or they can buy one there."
--
-- ── 1. THE "MENTION McNEIL FOOTBALL" LINE IS PROMOTED, NOT ADDED ──
-- 192 already carried it, inherited from the Phil's & Amy's precedent, but it
-- sat mid-sentence after the date and time where a skimmer slides past it. It is
-- now its own sentence, in the imperative, immediately after the when-and-where,
-- and it says WHY: it is the only thing that tells the restaurant the sale
-- belongs to McNeil.
--
-- 🚨 THIS SENTENCE IS THE WHOLE FUNDRAISER. A spirit night where nobody mentions
-- the school raises exactly nothing -- the restaurant has no way to attribute
-- the sale, so the family spends the money and the club gets none of it. That is
-- a worse outcome than not running the event, because it also spends goodwill.
-- 🚫 Do not shorten, soften, or move it below the fold in any future edit, and
-- do not drop it when this copy is reused for the next spirit night.
--
-- ── 2. THE SHIRT LINE, AND WHAT IT QUIETLY COMMITS THE CLUB TO ──
-- "Wear your Mav shirt. If you do not have one, you can buy one there."
--
-- ⚠️ THE SECOND HALF IS AN OPERATIONAL PROMISE, NOT JUST COPY. It tells families
-- merch will be ON SITE at both of these. If nobody brings the merch table, the
-- page has told people something untrue and they will look for it. The club does
-- run merch tables at games (the 9/1 newsletter asked for volunteers to staff
-- them), so this is plausible -- but it needs a person for Sep 14 and Sep 30
-- specifically. Flagged to Jeremy 2026-09-08.
--
-- ⚠️ NOTHING TO LINK IT TO. There is no merch page or merch route anywhere on
-- the site (checked: no `merch` reference in app/, lib/ or components/), so the
-- sentence deliberately does not promise an online option. If a merch page is
-- ever built, this is one of the places that should link to it.
--
-- Times, venues, slugs and status are untouched; this is copy only.
--
-- DB-ONLY, NO DEPLOY. /events, the event pages and the homepage read at request
-- time.
--
-- Rollback: 193_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug like 'spirit-night-%' and status = 'published';
  if n <> 2 then raise exception 'expected 2 published spirit nights, found %', n; end if;

  select count(*) into n from events
   where slug like 'spirit-night-%' and description like '%Wear your Mav shirt%';
  if n <> 0 then raise exception 'the shirt line is already present (already applied?)'; end if;
end $$;

update events
   set description = 'Join the Mavs for a Spirit Night at The League Kitchen & Tavern (Avery and Parmer) on Monday, September 14, 6:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-the-league-2026-09-14';

update events
   set description = 'Join the Mavs for a Spirit Night at Mighty Fine Burgers at Arbor Walk on Wednesday, September 30, 6:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-mighty-fine-2026-09-30';

do $$
declare n int;
begin
  -- Both carry the mention instruction AND the reason it matters.
  select count(*) into n from events
   where slug like 'spirit-night-%'
     and description like '%mention McNeil Football at the register%'
     and description like '%tells them your purchase counts%';
  if n <> 2 then raise exception 'the mention line is not complete on both (%)', n; end if;

  select count(*) into n from events
   where slug like 'spirit-night-%'
     and description like '%Wear your Mav shirt%'
     and description like '%you can buy one there%';
  if n <> 2 then raise exception 'the shirt line is not on both (%)', n; end if;

  -- Copy only: dates, venues and status must be exactly as 192 left them.
  select count(*) into n from events
   where slug like 'spirit-night-%' and status = 'published' and venue_id is not null
     and extract(hour from starts_at at time zone 'America/Chicago') = 18
     and extract(hour from ends_at at time zone 'America/Chicago') = 20;
  if n <> 2 then raise exception 'a spirit night date, venue or status changed (%)', n; end if;
end $$;

commit;

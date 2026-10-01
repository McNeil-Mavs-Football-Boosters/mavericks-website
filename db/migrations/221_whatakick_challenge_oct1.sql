-- 221_whatakick_challenge_oct1.sql
--
-- Whataburger WhataKick Challenge at halftime of the JV game vs Cedar Ridge,
-- Thu Oct 1, Maverick Stadium. From Kendra's 9/25 email (all approvals in).
--
-- ⚠️ KICKOFF IS 5:30, NOT KENDRA'S 6:00. Her email says 6:00; Coach's Week 9
-- graphic says 5:30 (migration 219). Jeremy 2026-09-28: "go with 5:30 time."
-- Her signup-table time (5:25) is kept as she wrote it; it is her fact, not
-- derived from kickoff. Entries close at the end of the first quarter.
--
-- Games have no detail page, so Kendra's "add a note to the game event page"
-- becomes (a) this events row, the one shareable URL for the announcement email,
-- and (b) a short `notes` on the JV game row, which renders under the row on
-- /schedule/games/jv and appends to the game's calendar title.
-- starts_at = kickoff; ends_at NULL (no end supplied, 197 precedent).
-- Description is plain prose: the /events list card and ICS render it raw.
--
-- DB-ONLY, NO DEPLOY. Rollback: 221_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'whatakick-challenge-2026-10-01';
  if n <> 0 then raise exception 'event already exists'; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv' and g.home_or_away = 'home'
     and g.game_date = timestamptz '2026-10-01 17:30 America/Chicago'
     and g.opponent = 'Cedar Ridge High School' and v.name = 'Maverick Stadium'
     and g.notes is null;
  if n <> 1 then raise exception 'JV Oct 1 not found at 5:30 home, Maverick Stadium, notes empty (%)', n; end if;
end $$;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, status)
select
  'Whataburger WhataKick Challenge at the JV Game',
  'whatakick-challenge-2026-10-01',
  'Halftime of the JV game vs Cedar Ridge will feature the Whataburger WhataKick Challenge! One student or fan will be selected at random to attempt a 30-yard field goal for a chance to win a $20 Whataburger gift card. Kickoff is 5:30 PM. Visit the signup table near the home entrance beginning at 5:25 PM and enter before the end of the first quarter. The McNeil Majestics and cheer team will lead a rally-towel entrance and crowd towel wave right before the kick. Whataburger rally towels and free-burger coupons will be available while supplies last. Bring the family and fill the stands!',
  timestamptz '2026-10-01 17:30 America/Chicago',
  null,
  'Maverick Stadium',
  v.id,
  'published'
from venues v where v.name = 'Maverick Stadium';

update games
   set notes = 'WhataKick Challenge at halftime', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-10-01 17:30 America/Chicago'
   and opponent = 'Cedar Ridge High School';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'whatakick-challenge-2026-10-01' and e.status = 'published'
     and v.name = 'Maverick Stadium'
     and extract(hour from e.starts_at at time zone 'America/Chicago') = 17
     and extract(minute from e.starts_at at time zone 'America/Chicago') = 30
     and e.description like '%Kickoff is 5:30 PM%'
     and e.description not like '%6:00%'
     and position(chr(8212) in e.description) = 0
     and e.description not like '%http%';
  if n <> 1 then raise exception 'WhataKick event not as intended (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv' and notes = 'WhataKick Challenge at halftime';
  if n <> 1 then raise exception 'JV note not set on exactly one row (%)', n; end if;
end $$;

commit;

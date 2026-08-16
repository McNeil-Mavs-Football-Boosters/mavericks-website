-- 132_eastview_scrimmage_location.sql
--
-- Puts the venue on the four Aug 20 Eastview rows: 'Maverick Stadium'.
--
-- ⚠️ This REVERSES a decision made in migration 130 hours earlier. 130 left
-- location NULL on purpose, reasoning that `home_or_away = 'home'` already says
-- where it is and that the Aug 13 Hendrickson rows carry no location either.
-- Two things changed since:
--   1. The Print View PDF now names the venue on those rows (Maverick Stadium),
--      so the site saying nothing where its own PDF says something is a gap.
--   2. The games rows are about to be rendered onto /events, the month view and
--      the ICS feed. A calendar entry with no location is materially worse than
--      a schedule table with an empty SITE cell - a phone calendar shows the
--      location under the title and offers directions from it.
-- Documented rather than quietly re-done: 130's note is wrong now, and anyone
-- reading it needs to land here.
--
-- 'Maverick Stadium' is the exact string the other home rows in this table use
-- (JV and freshman home games), so the games tables stay internally consistent
-- and the calendar entries read the same as every other home fixture. Varsity
-- home DISTRICT games are at 'KRAC' and are untouched - the scrimmage is the
-- exception, which is the whole point.
--
-- The past Aug 13 Hendrickson rows are deliberately left NULL. They are done,
-- nobody is navigating to them, and editing played rows earns nothing.

begin;

update games
   set location = 'Maverick Stadium'
 where year = '2026-27'
   and opponent = 'Eastview High School'
   and location is null;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and location = 'Maverick Stadium';
  if n <> 4 then raise exception 'expected 4 Eastview rows at Maverick Stadium, got %', n; end if;

  -- Nothing else in the season should have lost or gained a venue.
  select count(*) into n from games
   where year = '2026-27' and game_date >= '2026-08-20' and location is null;
  if n <> 0 then raise exception '% upcoming games still have no venue', n; end if;
end $$;

commit;

-- /schedule/games/* reads at request time: live with no deploy.

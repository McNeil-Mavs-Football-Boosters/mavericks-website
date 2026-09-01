-- 177_varsity_home_opener_krac.sql
--
-- The varsity home opener moves stadiums, three days out.
--
--   Fri Sep 4, varsity vs Lake Belton
--     Round Rock High School Dragon Stadium  ->  Kelly Reeves Athletic Complex
--     location 'Dragon Stadium'              ->  'KRAC'
--
-- Jeremy 2026-09-01. **The 7:00 p.m. kickoff does NOT change** -- he restated it,
-- and the row already held 19:00, so this migration deliberately does not touch
-- game_date. Confirmed before writing rather than assumed.
--
-- ── WHY 'KRAC' AND NOT THE FULL NAME ──
-- Every other Kelly Reeves game in `games` writes `location = 'KRAC'` (checked:
-- it is the only distinct value across all of them), and the school's PDF uses
-- KRAC in its SITE column too. Matching the surrounding rows wins, the same call
-- 155 made when it used 'Maverick Stadium' because that is what the PDF already
-- said. The `venues` row carries the full name and the verified map pin.
--
-- The KRAC venue row already exists with coordinates, so this is a repoint, not a
-- new venue: no risk of a second Kelly Reeves row with a guessed address.
--
-- ⚠️ THE PRINTED SCHEDULE SAYS DRAGON STADIUM AND IS PATCHED IN THE SAME SITTING
-- (`documents/schedules/2026-27-r3.pdf`, migration 178). Yesterday's Senior Night
-- fix is the whole reason that is stated here: a game-data change that stops at
-- the database leaves the downloadable schedule lying, and that one went twelve
-- days before Jeremy caught it. Do not split these two across sessions.
--
-- ⚠️ THE 8/31 NEWSLETTER NAMES DRAGON STADIUM AND ITS STREET ADDRESS, TWICE, in
-- a paragraph whose whole point is "put the address in your phone now". If it has
-- already gone out, that correction is a follow-up email, not a quiet edit.
--
-- DB-ONLY, NO CODE DEPLOY. /schedule/games/*, /events, the month view and the ICS
-- feed all read at request time, so the new venue and pin go live on commit.
--
-- Rollback: 177_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.id = '929405f5-70be-449f-80a2-8abd9e586ee4'
     and g.year = '2026-27' and g.team_level = 'varsity'
     and g.opponent = 'Lake Belton High School'
     and g.game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and g.location = 'Dragon Stadium'
     and v.name = 'Round Rock High School Dragon Stadium';
  if n <> 1 then
    raise exception 'Sep 4 varsity is not the Dragon Stadium 7:00 row this expects (found %)', n;
  end if;

  if not exists (select 1 from venues
                  where name = 'Kelly Reeves Athletic Complex' and latitude is not null) then
    raise exception 'Kelly Reeves venue row missing or has no pin; do not create one by guess';
  end if;
end $$;

update games
   set location = 'KRAC',
       venue_id = (select id from venues where name = 'Kelly Reeves Athletic Complex'),
       updated_at = now()
 where id = '929405f5-70be-449f-80a2-8abd9e586ee4';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.id = '929405f5-70be-449f-80a2-8abd9e586ee4'
     and g.location = 'KRAC' and v.name = 'Kelly Reeves Athletic Complex'
     and g.game_date = timestamptz '2026-09-04 19:00 America/Chicago'
     and g.home_or_away = 'home';
  if n <> 1 then raise exception 'Sep 4 varsity did not move to KRAC at 7:00 home'; end if;

  -- Nothing else may have moved, and no other game may still sit at Dragon.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and v.name = 'Round Rock High School Dragon Stadium';
  if n <> 1 then
    raise exception 'expected exactly 1 remaining Dragon Stadium game (the Oct 22 JV away), found %', n;
  end if;

  -- location and venue must not disagree anywhere in the season.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and v.name = 'Kelly Reeves Athletic Complex' and g.location <> 'KRAC';
  if n <> 0 then raise exception '% Kelly Reeves games do not say KRAC', n; end if;
end $$;

commit;

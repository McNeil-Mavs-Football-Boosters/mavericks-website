-- 205_week8_wed_kickoffs_confirmed.sql
--
-- Coach Gardner, Tue 22 Sep 2026 (relayed by Jeremy the same afternoon):
--   "I can confirm times for our games tomorrow. JV will play at 6:00PM at
--    Lake Travis Track Stadium. The Freshman will play here at McNeil Stadium
--    at 5:30PM."
--
--   JV              Wed Sep 23  6:00 PM  Lake Travis Track Stadium   <- was tbd/6:00 at "Lake Travis HS" (Cavalier Stadium)
--   Freshman Green  Wed Sep 23  5:30 PM  Maverick Stadium            <- was tbd/6:30 (school export)
--   Varsity         Thu Sep 24  7:00 PM  KRAC                        <- untouched
--
-- Closes 203, which set both rows to result_status 'tbd' on Coach's "Time TBA -
-- Location TBA". 130's shape: UPDATE game_date and put result_status back to
-- 'scheduled' in the same statement, so the rows re-enter /events and the ICS
-- at the right time and never at the placeholder.
--
-- ── THE JV VENUE IS NEW: A SECOND FIELD ON THE LAKE TRAVIS CAMPUS ──
-- The school's export put JV at "Lake Travis HS", which 057/155-era work mapped
-- to the Cavalier Stadium venue row (the football stadium). Coach says the TRACK
-- stadium. Same pattern as the Toney Burger Annex (155): two fields in one
-- complex, so a second `venues` row that shares the campus address. Named
-- exactly as Coach wrote it. ⚠️ latitude/longitude are left NULL and the maps
-- URL is an address search, not a pin: nobody here has verified where on the
-- campus the track sits, and a confident pin on the wrong field is worse than a
-- campus-level address (the "Lake Travis High School" venue row already works
-- this way). If someone confirms the spot, fill the pin in a later migration.
-- The game's `notes` says "not Cavalier Stadium" out loud, because a family
-- that went to Cavalier for a JV game before would otherwise go there again.
--
-- "McNeil Stadium" is what this club's rows call 'Maverick Stadium' (155/191):
-- same place, no venue change for the freshmen.
--
-- ── THE PRACTICE BODIES CARRY THE SAME FACT AND ARE FIXED HERE, NOT LATER ──
-- 202 wrote "kickoff times to be announced" / "Kickoff time to be announced"
-- into the varsity/JV and freshman bodies' pointers. 176's rule: a fact that
-- lives on two surfaces changes on both in one migration. Text replaced, and
-- the verify block fails if any body still says "to be announced".
--
-- ⚠️ THE HIDDEN BLUE ROW IS LEFT AT 5:00, same call as 155/173/191/199/203.
--
-- ⚠️ THE 9/21 NEWSLETTER SAID "please do not assume 6:00" and pointed at the
-- schedule page. JV IS 6:00; freshmen are 5:30, half an hour EARLIER than the
-- school's 6:30 and the direction that strands a family. The email told people
-- to check the page, and the page is now right. Jeremy to decide whether a
-- SportsYou/one-line note goes out; nothing here does that.
--
-- DB-ONLY, NO DEPLOY. /schedule/*, /events and the ICS read at request time.
--
-- Rollback: 205_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv'
     and game_date = timestamptz '2026-09-23 18:00 America/Chicago'
     and opponent = 'Lake Travis High School' and result_status = 'tbd'
     and location = 'Lake Travis HS';
  if n <> 1 then raise exception 'JV Sep 23 not found tbd at Lake Travis HS (found %, already applied?)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-23 18:30 America/Chicago'
     and opponent = 'Lake Travis High School' and result_status = 'tbd'
     and location = 'Maverick Stadium';
  if n <> 1 then raise exception 'freshman Green Sep 23 not found tbd at 6:30 (found %, already applied?)', n; end if;

  select count(*) into n from venues where name = 'Lake Travis Track Stadium';
  if n <> 0 then raise exception 'Lake Travis Track Stadium venue already exists'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%## Week 8 — September 21–25%'
     and body like '%to be announced%';
  if n <> 3 then raise exception 'expected 3 Week 8 bodies still saying "to be announced", found %', n; end if;
end $$;

insert into venues (name, address, maps_url, latitude, longitude)
values (
  'Lake Travis Track Stadium',
  '3324 Ranch Road 620 S, Austin, TX 78738',
  'https://maps.google.com/?q=Lake+Travis+High+School+Track+Stadium+3324+Ranch+Road+620+S+Austin+TX+78738',
  null,
  null
);

update games g
   set venue_id = v.id,
       location = 'Lake Travis Track Stadium',
       notes = 'Track stadium, not Cavalier Stadium',
       result_status = 'scheduled',
       updated_at = now()
  from venues v
 where v.name = 'Lake Travis Track Stadium'
   and g.year = '2026-27' and g.team_level = 'jv'
   and g.game_date = timestamptz '2026-09-23 18:00 America/Chicago'
   and g.opponent = 'Lake Travis High School';

update games
   set game_date = timestamptz '2026-09-23 17:30 America/Chicago',
       result_status = 'scheduled',
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and game_date = timestamptz '2026-09-23 18:30 America/Chicago'
   and opponent = 'Lake Travis High School';

-- Practice bodies: the pointers now carry the confirmed times.
update practice_schedules
   set body = replace(replace(body,
       'JV plays **Wednesday Sep 23** and varsity plays **Thursday Sep 24**. See the Games schedule for times and locations.',
       'JV plays **Wednesday Sep 23 at 6:00 p.m.** at Lake Travis Track Stadium (not Cavalier Stadium) and varsity plays **Thursday Sep 24 at 7:00 p.m.** at Kelly Reeves. See the Games schedule.'),
       'JV and freshmen Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.',
       'freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Lake Travis Track Stadium, varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
   set body = replace(replace(body,
       '(Sep 23), not Thursday. Kickoff time to be announced — see the Games schedule.',
       '(Sep 23), not Thursday. **Kickoff 5:30 p.m. at Maverick Stadium** (home). See the Games schedule.'),
       'freshmen and JV Wednesday Sep 23 (kickoff times to be announced), varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.',
       'freshmen Wednesday Sep 23 at 5:30 p.m. at Maverick Stadium, JV Wednesday Sep 23 at 6:00 p.m. at Lake Travis Track Stadium, varsity Thursday Sep 24 at 7:00 p.m. at Kelly Reeves Athletic Complex.'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

do $$
declare n int;
begin
  select count(*) into n from games where year = '2026-27' and result_status = 'tbd';
  if n <> 0 then raise exception '% rows still tbd', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv'
     and g.game_date = timestamptz '2026-09-23 18:00 America/Chicago'
     and g.location = 'Lake Travis Track Stadium' and v.name = 'Lake Travis Track Stadium'
     and g.home_or_away = 'away' and g.result_status = 'scheduled';
  if n <> 1 then raise exception 'JV row not as intended'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date = timestamptz '2026-09-23 17:30 America/Chicago'
     and location = 'Maverick Stadium' and home_or_away = 'home' and result_status = 'scheduled';
  if n <> 1 then raise exception 'freshman Green row not as intended'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Blue'
     and game_date = timestamptz '2026-09-23 17:00 America/Chicago' and result_status = 'scheduled';
  if n <> 1 then raise exception 'the hidden Blue Sep 23 row was disturbed'; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = timestamptz '2026-09-24 19:00 America/Chicago' and location = 'KRAC';
  if n <> 1 then raise exception 'varsity Sep 24 was disturbed'; end if;

  -- Nothing else on the Lake Travis campus row moved: Cavalier Stadium still exists for later use.
  select count(*) into n from venues where name in ('Cavalier Stadium', 'Lake Travis Track Stadium');
  if n <> 2 then raise exception 'venue rows not as expected (%)', n; end if;

  -- Both replacements landed on all three bodies and no "to be announced" survives.
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%to be announced%';
  if n <> 0 then raise exception '% practice bodies still say "to be announced"', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27'
     and body like '%5:30 p.m. at Maverick Stadium%'
     and body like '%6:00 p.m. at Lake Travis Track Stadium%';
  if n <> 3 then raise exception 'confirmed kickoffs missing from % bodies', 3 - n; end if;

  -- 🚫 The later Green rows were not bulk-moved (199 counted six at 6:30 after Sep 17; Sep 23 leaves five).
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
     and game_date > timestamptz '2026-09-24 00:00 America/Chicago'
     and extract(hour from game_date at time zone 'America/Chicago') = 18
     and extract(minute from game_date at time zone 'America/Chicago') = 30;
  if n <> 5 then raise exception 'expected 5 later Green rows still at 6:30, found %', n; end if;
end $$;

commit;

-- 155_week4_game_times_burger_annex.sql
--
-- Source: Coach's "THIS WEEK'S SCHEDULE" graphic for Aug 27-28 (Jeremy, 2026-08-23).
-- It is the newest publication and it supersedes the school's April 28 schedule
-- PDF for these three rows. What it says, and what we held before:
--
--   FRESHMEN  Thu Aug 27  BURGER ANNEX        5:00 pm   (site had 6:30, Burger Stadium)
--   JV        Thu Aug 27  McNeil High School  6:00 pm   (site already correct - NOT touched)
--   VARSITY   Fri Aug 28  Burger Stadium      7:30 pm   (site had 7:00)
--
-- THREE things move, and the JV row is deliberately left alone. Its DB row already
-- reads Thursday 6:00 p.m. at Maverick Stadium, which is the same place the graphic
-- calls "McNeil High School" - 'Maverick Stadium' is the wording the school's own PDF
-- uses for McNeil's stadium in every JV and freshman home row, so renaming it to match
-- the graphic would put the site back in disagreement with its own Print View for no
-- gain. Verified against the original PDF (JV table, Aug. 27: Maverick Stadium / H /
-- 6:00) before deciding not to touch it.
--
-- 1. BURGER ANNEX IS A SEPARATE VENUE ROW, same address as the stadium.
--    Austin ISD's Toney Burger Athletic Center holds two football fields: Burger
--    Stadium (~15,000 seats, turf, locker rooms) and the Burger Annex (~680 seats,
--    press box and scoreboard, no dressing or training facilities). Sub-varsity plays
--    the annex; varsity plays the stadium the following night. They are different
--    fields at 3200 Jones Road, and a parent who walks into the stadium for a 5:00
--    freshman game is at the wrong field.
--    Modelled as a second `venues` row rather than as a label-only change because
--    `location` is the display string and `venues` is the pin: one row per physical
--    place is the table's rule (migration 134), and the annex is a physical place.
--
--    ⚠️ THE ANNEX REUSES THE STADIUM'S VERIFIED PIN ON PURPOSE. The two fields are
--    ~200 m apart inside one complex off one entrance, and there is no separately
--    verified coordinate for the annex. Reusing the checked pin puts parents in the
--    right parking lot off the right road; inventing coordinates for the annex would
--    put an unverified pin on the map, which migration 145/146 spent two migrations
--    getting rid of. The display label is what tells them which field. If a verified
--    annex coordinate ever turns up, it is a one-row UPDATE.
--
-- 2. The freshman Aug 27 rows move to the annex - BOTH of them, including the hidden
--    Blue row. `freshman_has_blue` is false (migration 148) so only the Green row is
--    visible on /schedule/games/freshman, /events, the month view and the ICS feed;
--    the Blue row is still in `games`. Updating only the visible one would leave a
--    row in the table asserting the freshman game is at Burger Stadium, and a raw
--    `games` query would disagree with the site. This does NOT migrate or delete the
--    Blue rows - Jeremy's 2026-08-22 call that they stay is unchanged.
--
--    The Blue row's TIME is left at 5:00 because that is where it already sat (the
--    school's footnote is "Blue @ 5:00 / Green @ 6:30"). Green moves 6:30 -> 5:00, so
--    both freshman rows now read 5:00 for this one date. That is correct for a single
--    freshman team and harmless while Blue is hidden. Later weeks keep 6:30 until
--    Coach publishes otherwise - this is a WEEK-SPECIFIC change, not a season rule.
--
-- 3. Varsity 7:00 -> 7:30. The school's PDF says 7:00 for every varsity game and the
--    graphic says 7:30 for this one. Jeremy's call 2026-08-23: the graphic wins and
--    the Print View PDF gets patched to match, so the site, the calendar feed and the
--    printed schedule all say 7:30 (see scripts/patch-schedule-pdf.py).
--
-- Times are written as America/Chicago literals; Aug 2026 is CDT (UTC-5).

begin;

insert into venues (name, address, maps_url, latitude, longitude)
values (
  'Toney Burger Annex',
  '3200 Jones Road, Austin, TX',
  'https://www.google.com/maps/place/Burger+Stadium/@30.2305155,-97.8123217,16z/data=!3m1!4b1!4m6!3m5!1s0x865b4b144a13f911:0xf29b3922fac942ba!8m2!3d30.2305155!4d-97.8097468!16s%2Fm%2F0k0bh48',
  30.2305155,
  -97.8097468
)
on conflict (name) do nothing;

-- Freshman Aug 27: venue + label to the annex (both rows), Green's time to 5:00.
update games
   set location = 'Burger Annex',
       venue_id = (select id from venues where name = 'Toney Burger Annex')
 where year = '2026-27'
   and team_level = 'freshman'
   and game_date >= '2026-08-27 00:00:00 America/Chicago'
   and game_date <  '2026-08-28 00:00:00 America/Chicago';

update games
   set game_date = '2026-08-27 17:00:00 America/Chicago'
 where year = '2026-27'
   and team_level = 'freshman'
   and team_designation = 'Green'
   and game_date >= '2026-08-27 00:00:00 America/Chicago'
   and game_date <  '2026-08-28 00:00:00 America/Chicago';

-- Varsity Aug 28: 7:00 -> 7:30.
update games
   set game_date = '2026-08-28 19:30:00 America/Chicago'
 where year = '2026-27'
   and team_level = 'varsity'
   and game_date >= '2026-08-28 00:00:00 America/Chicago'
   and game_date <  '2026-08-29 00:00:00 America/Chicago';

do $$
declare n int;
begin
  -- Both freshman Aug 27 rows sit at the annex, at 5:00, still away.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'freshman'
     and g.game_date = '2026-08-27 17:00:00 America/Chicago'
     and g.location = 'Burger Annex' and v.name = 'Toney Burger Annex'
     and g.home_or_away = 'away';
  if n <> 2 then raise exception 'expected 2 freshman rows at Burger Annex 5:00, got %', n; end if;

  -- Nothing freshman-shaped is left at the stadium on that date.
  select count(*) into n from games
   where year = '2026-27' and team_level = 'freshman' and location = 'Burger Stadium';
  if n <> 0 then raise exception '% freshman rows still labelled Burger Stadium', n; end if;

  -- Varsity is the ONLY remaining Burger Stadium row, and it reads 7:30.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location = 'Burger Stadium'
     and v.name = 'Toney Burger Stadium';
  if n <> 1 then raise exception 'expected 1 Burger Stadium game (varsity), got %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and game_date = '2026-08-28 19:30:00 America/Chicago';
  if n <> 1 then raise exception 'varsity Aug 28 is not at 7:30 p.m. CT (matched % rows)', n; end if;

  -- The JV row is untouched: Thursday 6:00 p.m. at Maverick Stadium, home.
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv'
     and g.game_date = '2026-08-27 18:00:00 America/Chicago'
     and g.location = 'Maverick Stadium' and v.name = 'Maverick Stadium'
     and g.home_or_away = 'home';
  if n <> 1 then raise exception 'JV Aug 27 row was disturbed (matched % rows)', n; end if;

  -- Invariant carried from 145/146: every 2026-27 game keeps a venue with a pin.
  select count(*) into n from games g left join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location is not null
     and (v.id is null or v.latitude is null);
  if n <> 0 then raise exception '% 2026-27 games lack a verified pin', n; end if;
end $$;

commit;

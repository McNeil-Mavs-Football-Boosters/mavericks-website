-- 236_homecoming_tunnel_stampede_2026.sql
--
-- 2026 McNeil Homecoming Tunnel Stampede, Fri Oct 23, KRAC, before the varsity
-- Homecoming game vs Round Rock (7:00). Jeremy 2026-10-12: "add the Homecoming
-- Tunnel Stampede to the events tab... The event is live on Eventbrite.
-- Tinyurl.com/2026TunnelStampede".
--
-- Facts read from the Eventbrite page itself (organizer: McNeil Mavericks
-- Football Booster Club), not retyped from a flyer:
--   6:00-6:30 participant arrival + check-in at the HOME side ticket booth
--     (t-shirt + wristband matched to a parent's band)
--   6:30-6:40 JV players group participants by grade and line them up
--   6:40      Tunnel Stampede
--   6:45      trophy to the school with the most registered students; parents
--             collect at the home ticket booth end of the field
--   Eventbrite's own window is 6:00-7:30 PM, used for starts_at / ends_at.
--   Registration includes the participant's t-shirt and game ticket, NOT
--   parent tickets. A child who wants only the shirt still registers.
--
-- ⚠️ signup_url is the DIRECT Eventbrite URL, not the tinyurl. The tinyurl
-- redirects through a viglink affiliate tracker before reaching Eventbrite;
-- the site should not route parents through that hop. Share-tracking query
-- params (aff/utm) dropped. The tinyurl stays fine for flyers and email.
--
-- No price stated: Eventbrite shows it at checkout and owns any change.
-- Description is plain prose, no URL (list card + ICS render it raw, 150/221).
-- games.notes on the varsity Oct 23 row already says 'Homecoming'; untouched.
--
-- DB-ONLY, NO DEPLOY. Rollback: 236_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'homecoming-tunnel-stampede-2026';
  if n <> 0 then raise exception 'event already exists'; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'varsity' and g.home_or_away = 'home'
     and g.game_date = timestamptz '2026-10-23 19:00 America/Chicago'
     and g.opponent = 'Round Rock High School' and g.notes = 'Homecoming'
     and v.name = 'Kelly Reeves Athletic Complex';
  if n <> 1 then raise exception 'Homecoming game not found as expected (%)', n; end if;
end $$;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id,
                    signup_url, signup_label, status)
select
  'Homecoming Tunnel Stampede',
  'homecoming-tunnel-stampede-2026',
  'Calling all future Mavericks! Elementary and middle school students who will attend McNeil High School are invited to run out of the tunnel with the team to kick off the Homecoming game vs Round Rock. The school with the most students registered takes home the Homecoming Tunnel Stampede trophy and bragging rights for the year. Participants arrive at 6:00 PM at the HOME side ticket booth to check in and pick up their Tunnel Stampede t-shirt and a wristband. At 6:30 PM JV players group them by grade and walk them to the tunnel, and the Stampede runs at 6:40 PM. Parents drop off and sit in the Tunnel Stampede bleachers on the HOME side, then meet their student at the home ticket booth end of the field after the trophy presentation, where booster club members match wristbands. Registration includes the participant''s t-shirt and a game ticket. Parent game tickets are NOT included; buy them in advance from Round Rock ISD Athletics. Every child who wants a t-shirt needs to register, even if they do not plan to run.',
  timestamptz '2026-10-23 18:00 America/Chicago',
  timestamptz '2026-10-23 19:30 America/Chicago',
  'Kelly Reeves Athletic Complex (home side)',
  v.id,
  'https://www.eventbrite.com/e/2026-mcneil-homecoming-tunnel-stampede-tickets-2003268329500',
  'Register on Eventbrite',
  'published'
from venues v where v.name = 'Kelly Reeves Athletic Complex';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'homecoming-tunnel-stampede-2026' and e.status = 'published'
     and v.name = 'Kelly Reeves Athletic Complex'
     and e.starts_at = timestamptz '2026-10-23 18:00 America/Chicago'
     and e.ends_at   = timestamptz '2026-10-23 19:30 America/Chicago'
     and e.signup_url like 'https://www.eventbrite.com/e/%-2003268329500'
     and e.signup_url not like '%?%'
     and e.description like '%6:40 PM%'
     and e.description like '%Parent game tickets are NOT included%'
     and position(chr(8212) in e.description) = 0
     and e.description not like '%http%';
  if n <> 1 then raise exception 'Tunnel Stampede event not as intended (%)', n; end if;
end $$;

commit;

-- 161_ticket_urls_and_mavmail.sql
--
-- Ticket links on the schedule, plus fixing the Mav Mail rows on /resources.
-- Jeremy + Kendra, 2026-08-25: ticket info is currently only published in Mav
-- Mail (RRISD's newsletter, not ours) and belongs on the booster site.
--
-- ── WHY THE LINK LIVES ON THE VENUE ──
-- RRISD sells through HomeTown Ticketing and every game LEVEL is its own event
-- ("McNeil HS Varsity Football vs Lake Belton", "JV Football McNeil HS vs
-- Bowie"). But those per-event URLs cannot be stored: varsity tickets are only
-- published at 8:00 AM the Monday before each game and JV/freshman on game day,
-- so on 2026-08-25 only NINE event links existed for the whole season. Storing
-- /embed/event/<id> would leave most of the season null and rot as ids appear.
--
-- What IS durable is the HOST's box office page, and the host follows the VENUE,
-- not home/away -- the Cedar Ridge, Westwood and Round Rock games are *away*
-- games played at RRISD venues. Jeremy: "i think we can find general links for
-- every game even if the game tix are not available yet." So: one link per
-- venue, and every level gets a link.
--
-- `games.ticket_url` is a per-game OVERRIDE for one-offs (a playoff at a neutral
-- site, or a district posting a special link). Resolution is
-- `game.ticket_url ?? venue.ticket_url`, and null renders NOTHING -- no
-- placeholder, no dead link.
--
-- ⚠️ Lake Travis is NOT on HomeTown, it is on Hudl. That is the reason this is a
-- stored per-venue value and not a URL computed from a district slug.
--
-- ⚠️ Kelly Reeves hosts both McNeil home AND away games, so a venue-level value
-- cannot distinguish them. All RRISD venues get McNeil's own entity page (the
-- link Jeremy confirmed people use). If an away-at-RRISD game turns out not to be
-- listed there, set that game's `ticket_url` override to the district-wide box
-- office `https://events.hometownticketing.com/boxoffice/roundrockisd`.
--
-- Lake Belton High School is deliberately left NULL -- Belton ISD's box office
-- was not supplied. It renders no link, which is the honest state.

begin;

alter table venues add column if not exists ticket_url text;
alter table games  add column if not exists ticket_url text;

comment on column venues.ticket_url is
  'Host district box office page for events at this venue. The durable link; per-event ticket URLs only exist the week of the game.';
comment on column games.ticket_url is
  'Per-game override. Wins over venues.ticket_url. For one-offs only; normally null.';

-- Round Rock ISD -- McNeil's own entity page
update venues set ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd/entity/schools/26'
where name in (
  'Maverick Stadium',
  'Kelly Reeves Athletic Complex',
  'Round Rock High School Dragon Stadium',
  'Cedar Ridge High School Football Stadium',
  'Westwood Warrior Bowl',
  'Stony Point Tiger Stadium'
);

-- Austin ISD -- from the Mav Mail issue of Sunday Aug 23 2026
update venues set ticket_url = 'https://events.hometownticketing.com/boxoffice/austinisd/L2VtYmVkL2FsbA%3D%3D'
where name in ('Toney Burger Stadium', 'Toney Burger Annex');

-- Leander ISD (Rouse, Vista Ridge)
update venues set ticket_url = 'https://events.hometownticketing.com/boxoffice/leanderisd'
where name in ('Gupton Stadium', 'Charles Rouse Stadium', 'Vista Ridge Football Field');

-- Eanes ISD (Westlake)
update venues set ticket_url = 'https://events.hometownticketing.com/boxoffice/eanesisd/entity/schools/4'
where name = 'Chaparral Stadium';

-- Lake Travis ISD -- Hudl, not HomeTown. Needed for the JV away game on 9/23.
update venues set ticket_url = 'https://fan.hudl.com/usa/tx/austin/organization/863/lake-travis-high-school/tickets'
where name = 'Cavalier Stadium';

-- ── /resources: the row labelled "MavMail" is actually the LIVE FEED ──
-- It points at mcneil.roundrockisd.org/o/mcneil/live-feed, which is the school's
-- post stream. Mav Mail is published on a different platform entirely
-- (roundrockisd.edurooms.com) and is never posted to the feed, which is why
-- Jeremy could not find this week's issue there. Relabel, then add the real
-- subscribe link and the ticket link.
update resource_links
set label = 'McNeil Live Feed',
    description = 'School announcements and posts from McNeil. Note: Mav Mail is not posted here.'
where section = 'communications'
  and label = 'MavMail'
  and url = 'https://mcneil.roundrockisd.org/o/mcneil/live-feed';

insert into resource_links (section, label, url, description, sort_order, active)
values
  ('communications', 'Subscribe to Mav Mail',
   'https://www.roundrockisd.org/o/rrisd/page/connect-with-rrisd',
   'RRISD''s weekly school newsletter. Football ticket links and campus news land here first.',
   -4, true),
  ('communications', 'Buy Football Tickets',
   'https://events.hometownticketing.com/boxoffice/roundrockisd/entity/schools/26',
   'McNeil''s HomeTown box office. Varsity tickets post at 8:00 AM the Monday before each game; JV and freshman on game day.',
   -5, true);

-- Guards. Fail the transaction rather than half-applying.
do $$
declare
  rrisd int; aisd int; leander int; eanes int; lt int; belton_null int;
  live_feed int; subscribe int; tix int;
begin
  select count(*) into rrisd from venues where ticket_url like '%roundrockisd/entity/schools/26';
  select count(*) into aisd from venues where ticket_url like '%austinisd%';
  select count(*) into leander from venues where ticket_url like '%leanderisd%';
  select count(*) into eanes from venues where ticket_url like '%eanesisd%';
  select count(*) into lt from venues where ticket_url like '%hudl.com%';
  select count(*) into belton_null from venues where name = 'Lake Belton High School' and ticket_url is null;
  select count(*) into live_feed from resource_links where label = 'McNeil Live Feed';
  select count(*) into subscribe from resource_links where label = 'Subscribe to Mav Mail';
  select count(*) into tix from resource_links where label = 'Buy Football Tickets';

  if rrisd <> 6 then raise exception 'expected 6 RRISD venues, got %', rrisd; end if;
  if aisd <> 2 then raise exception 'expected 2 Austin ISD venues, got %', aisd; end if;
  if leander <> 3 then raise exception 'expected 3 Leander ISD venues, got %', leander; end if;
  if eanes <> 1 then raise exception 'expected 1 Eanes ISD venue, got %', eanes; end if;
  if lt <> 1 then raise exception 'expected 1 Hudl venue, got %', lt; end if;
  if belton_null <> 1 then raise exception 'Lake Belton should still be null'; end if;
  if live_feed <> 1 then raise exception 'live feed relabel did not apply'; end if;
  if subscribe <> 1 then raise exception 'subscribe row missing'; end if;
  if tix <> 1 then raise exception 'ticket row missing'; end if;
  -- Nothing should still claim to be MavMail while pointing at the live feed.
  if exists (select 1 from resource_links where label = 'MavMail') then
    raise exception 'a row still labelled MavMail';
  end if;
end $$;

commit;

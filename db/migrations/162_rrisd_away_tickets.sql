-- 162_rrisd_away_tickets.sql
--
-- Jeremy 2026-08-25: "maybe just use this general link
-- https://events.hometownticketing.com/boxoffice/roundrockisd/entity/schools/26
-- ... for homegames".
--
-- That splits the rule 161 assumed. 161 put McNeil's own entity page on every
-- RRISD venue, but a venue-level value cannot tell home from away and **Kelly
-- Reeves hosts both** -- home vs Lake Travis, Stony Point and Round Rock, away
-- vs Cedar Ridge and Westwood. Same for Dragon Stadium.
--
-- New split, and it is now explicit in code rather than inferred from the venue:
--   HOME game  -> MCNEIL_TICKETS_URL in lib/constants.ts (the schools/26 page)
--   AWAY game  -> venues.ticket_url, i.e. whoever is HOSTING
--
-- So the RRISD venue rows change from McNeil's entity page to the DISTRICT-wide
-- box office. That page lists every RRISD school's events, so an away game at
-- Cedar Ridge, Westwood or Stony Point resolves to a page the game is actually
-- on -- which McNeil's own entity page might not list.
--
-- Maverick Stadium is only ever a home venue, so its value is unused under the
-- new rule. Left populated anyway: it costs nothing and is correct if McNeil
-- ever appears as the visitor at its own stadium.

begin;

update venues
set ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd'
where ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd/entity/schools/26';

do $$
declare district int; stale int;
begin
  select count(*) into district from venues
   where ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd';
  select count(*) into stale from venues where ticket_url like '%entity/schools/26';
  if district <> 6 then raise exception 'expected 6 RRISD venues on the district link, got %', district; end if;
  if stale <> 0 then raise exception '% venue(s) still on the McNeil entity page', stale; end if;
end $$;

commit;

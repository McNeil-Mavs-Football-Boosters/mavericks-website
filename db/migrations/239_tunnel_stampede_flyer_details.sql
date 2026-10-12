-- 239_tunnel_stampede_flyer_details.sql
--
-- Jeremy 2026-10-12 sent the official flyer ("2026 Tunnel Stampede English.pdf")
-- and an annotated KRAC aerial ("Kelly Reeves Aerial - AR Notes.pdf"). Facts
-- they add to 236's Eventbrite-sourced description:
--   * Registration is $10 (flyer). Eventbrite charges 12.51 because it adds its
--     own fees, so the copy says "$10 plus Eventbrite fees".
--   * Registration closes Wednesday Oct 22 (flyer).
--   * The competing feeder schools: 11 elementary + 3 middle (flyer).
--   * A Feeder School Tailgate Area in the main (north) parking lot (aerial).
--   * Check-in sits at the stadium entrance off the main parking lot, where
--     parents enter; children are picked up on the walkway at the same end
--     (aerial). Kept the flyer's "HOME side ticket booth" wording alongside it.
-- ⚠️ The flyer prints mcneilfootballboosters@gmail.com for questions. The site
-- publishes no Gmail (064), so questions go to boosters@, which delivers to
-- the same inbox.
-- The map is NOT set as cover_image_url: renderers crop to 16:9 and would cut
-- the labels (197's portrait finding). It goes in the newsletter instead.
-- DB-ONLY, NO DEPLOY. Rollback: 239_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026' and description not like '%$10%';
  if n <> 1 then raise exception 'event not in its 236 state (%)', n; end if;
end $$;

update events set description =
  'Calling all future Mavericks! Elementary and middle school students who will attend McNeil High School are invited to run out of the tunnel with the team to kick off the Homecoming game vs Round Rock. The school with the most students registered takes home the Homecoming Tunnel Stampede trophy and bragging rights for the year. Feeder schools: Anderson Mill, Brushy Creek, Elsa England, Forest North, Joe Lee Johnson, Jollyville, Live Oak, Pond Springs, Purple Sage, Patsy Sommer and Wells Branch elementary, and Cedar Valley, Deerpark and Pearson Ranch middle. Registration is $10 plus Eventbrite fees and closes Wednesday, October 22. It includes the participant''s t-shirt and a game ticket. Parent game tickets are NOT included; buy them in advance from Round Rock ISD Athletics. Every child who wants a t-shirt needs to register, even if they do not plan to run. Participants arrive at 6:00 PM at the Tunnel Stampede check-in by the HOME side ticket booth, at the stadium entrance off the main parking lot, to pick up their t-shirt and a wristband. At 6:30 PM JV players group them by grade and walk them to the tunnel, and the Stampede runs at 6:40 PM. Parents drop off and sit in the Tunnel Stampede bleachers on the HOME side, then pick up their student on the walkway at that same end of the field after the trophy presentation, where booster club members match wristbands. Feeder school families can gather beforehand in the Feeder School Tailgate Area in the main parking lot. Questions: boosters@mcneilmavericks.org.',
  updated_at = now()
 where slug = 'homecoming-tunnel-stampede-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%$10 plus Eventbrite fees%'
     and description like '%closes Wednesday, October 22%'
     and description like '%Pearson Ranch%'
     and description like '%Tailgate Area%'
     and description not like '%gmail%'
     and description not like '%http%'
     and position(chr(8212) in description) = 0;
  if n <> 1 then raise exception 'description not as intended (%)', n; end if;
end $$;

commit;

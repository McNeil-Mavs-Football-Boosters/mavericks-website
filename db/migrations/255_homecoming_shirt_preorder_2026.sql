-- 255_homecoming_shirt_preorder_2026.sql
--
-- Homecoming 2026 roster shirt pre-order. Jeremy 2026-10-21: "add it to the
-- website". Board set $20 flat on 10/20 (hand vote). The form is a Payable /
-- Square Google Form built 10/20 (ops repo scripts/create-homecoming-shirt-form.gs):
--   * $20 each, Youth Large plus adult Small through XXXL
--   * orders close Thu Oct 22 at midnight (the form closes itself)
--   * card at checkout, or Venmo @McNeil-Football with "T-shirt" + name in the note
--   * pickup Friday night at the Booster Club merch table, which the 10/20 minutes
--     put outside the gate next to Stampede check-in, then inside
--
-- Dated as the PICKUP (Fri Oct 23, from Stampede check-in at 6:00 through the
-- game) so it lists beside the Stampede and retires itself after Friday. The
-- button still points at the form on Friday, when the form shows its own closed
-- message; that is the right thing for a late visitor to see.
--
-- cover_image_url is the mockup already hosted for the form (1400x881, close to
-- the 16:9 crop the renderers use; both shirts sit well inside the crop).
-- Description plain prose, no URL (list card + ICS render it raw, 150/221).
--
-- DB-ONLY, NO DEPLOY. Rollback: 255_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'homecoming-shirt-preorder-2026';
  if n <> 0 then raise exception 'event already exists'; end if;
end $$;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id,
                    signup_url, signup_label, cover_image_url, status)
select
  'Homecoming Roster Shirt Pre-Order',
  'homecoming-shirt-preorder-2026',
  'Pre-order now so you don''t miss out on your size! The 2026 Homecoming shirt is a heather grey tee with McNeil Mavericks, Austin TX on the front and the 2026 varsity roster and Homecoming 2026 on the back. $20 each, in Youth Large and adult Small through XXXL. Orders close Thursday, October 22 at midnight. Pay by card at checkout, or Venmo @McNeil-Football with T-shirt and your name in the note (Venmo saves the club the card fee). Pick up your shirts Friday night, October 23 at the Booster Club merch table at the Homecoming game vs Round Rock. Every purchase supports McNeil Mavericks Football.',
  timestamptz '2026-10-23 18:00 America/Chicago',
  timestamptz '2026-10-23 21:30 America/Chicago',
  'Kelly Reeves Athletic Complex, Booster Club merch table',
  v.id,
  'https://docs.google.com/forms/d/e/1FAIpQLSfiXhtzKtysdQFQ9sxNkAO2y7yPurLXQ32qQ9AUhdGx8nzr2w/viewform',
  'Order a Shirt',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/site-images/merch/homecoming-2026-roster-tee.jpg',
  'published'
from venues v where v.name = 'Kelly Reeves Athletic Complex';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'homecoming-shirt-preorder-2026' and e.status = 'published'
     and v.name = 'Kelly Reeves Athletic Complex'
     and e.signup_url like 'https://docs.google.com/forms/d/e/1FAIpQLSfiXhtzKtysdQFQ9sxNkAO2y7yPurLXQ32qQ9AUhdGx8nzr2w/viewform'
     and e.description like '%close Thursday, October 22 at midnight%'
     and e.description like '%@McNeil-Football%'
     and position(chr(8212) in e.description) = 0
     and e.description not like '%http%';
  if n <> 1 then raise exception 'shirt pre-order event not as intended (%)', n; end if;
end $$;

commit;

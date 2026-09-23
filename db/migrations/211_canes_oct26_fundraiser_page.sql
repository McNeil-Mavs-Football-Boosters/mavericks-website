-- 211_canes_oct26_fundraiser_page.sql
--
-- Raising Cane's created a fundraiser page for the Oct 26 spirit night and
-- Jeremy asked for it on the site (2026-09-22 evening):
--   https://raisingcanescommunity.com/event/ccbc5242-8ef0-4bde-9e31-7169156b4b18
--
-- Read with headless Chromium (Cloudflare 403s curl). What the page says:
--   * "Support McNeil Mavericks Football BoosterClub", Oct 26, **5-9pm**,
--     12901 N Interstate Hwy 35 BLDG 21, Austin, TX 78753.
--   * The club receives **15% of fundraiser Net Sales**. Participate by
--     mentioning the fundraiser at the register, or by applying mobile code
--     **RCFUND96** to online (raisingcanes.com) or Raising Cane's app orders.
--   * Excludes gift cards, retail merchandise, kiosk and catering orders.
--   * "Please note that your fundraiser can not be advertised at the Restaurant
--     during the event."
--   * Printable flyer (PDF + PNG) downloads on the page.
--
-- ── FOUR CHANGES TO THE OCT 26 ROW ──
-- 1. `signup_url` = the Cane's page, `signup_label` = 'Fundraiser Details'.
--    The event page renders `{signup_label ?? "Sign Up"} →` as a navy button
--    (app/events/[slug]/page.tsx); "Sign Up" would misdescribe a page nobody
--    signs up on (lib/types.ts note), so the label is set. The page carries
--    the code, the flyer downloads and directions, so one button covers it.
-- 2. ⚠️ `ends_at` 8:00 PM -> **9:00 PM**. Kendra's 9/22 email said 5-8 for all
--    three nights; Cane's own page says 5-9 for this one. The restaurant's
--    system is what gets honoured at the register, so the site follows it and
--    the prose moves with the timestamp (194). Flagged to Jeremy; if Kendra
--    confirms 8, it is a one-row revert. Nov 9 stays 5-8 (no Cane's page for
--    it yet) and Pok-e-Jo's is untouched.
-- 3. Description gains the 15% and the mobile code. 192 deliberately stated no
--    percentage because none was supplied; now the restaurant has published
--    one, which is the case 192 anticipated ("if a restaurant confirms one, it
--    can be added"). The code is stated because a family ordering in the app
--    without it raises nothing, same logic as the register line.
-- 4. 🚨 THE SHIRT / MERCH SENTENCE COMES OUT OF BOTH CANE'S NIGHTS. 193's "If
--    you do not have one, you can buy one there" promises a merch table at the
--    restaurant. Cane's terms say the fundraiser cannot be advertised at the
--    restaurant during the event, and a club table with shirts is exactly
--    that. Leaving it in tells families to expect something Cane's forbids.
--    "Wear your Mav shirt." stays; only the buy-one-there half goes. Removed
--    from Nov 9 as well since the same chain's terms apply, so the followups
--    merch-table item now covers three nights (Sep 15, Sep 30, Oct 14), not five.
--
-- ── WHAT IS NOT DONE ──
-- * `cover_image_url` is not set to the PNG flyer. followups.md: the cover slot
--   cannot show a portrait flyer, and Cane's flyers are 8.5x11 portrait. The
--   flyer is one click away behind the button instead.
-- * Nov 9 gets no link or code. RCFUND96 is this event's code; Cane's issues a
--   page per event and the Nov 9 one has not been shared. Do not reuse the code.
--
-- The register line ("Please mention McNeil Football at the register") is kept
-- and asserted -- Cane's says "mentioning the fundraiser at the register", same
-- mechanic.
--
-- DB-ONLY, NO DEPLOY. Rollback: 211_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'spirit-night-raising-canes-2026-10-26'
     and status = 'published' and signup_url is null
     and ends_at = timestamptz '2026-10-26 20:00 America/Chicago'
     and description like '%you can buy one there%';
  if n <> 1 then raise exception 'Oct 26 Cane''s row not as 210 left it (found %, already applied?)', n; end if;

  select count(*) into n from events
   where slug = 'spirit-night-raising-canes-2026-11-09'
     and description like '%you can buy one there%';
  if n <> 1 then raise exception 'Nov 9 Cane''s row not as 210 left it (found %)', n; end if;
end $$;

update events
   set ends_at = timestamptz '2026-10-26 21:00 America/Chicago',
       signup_url = 'https://raisingcanescommunity.com/event/ccbc5242-8ef0-4bde-9e31-7169156b4b18',
       signup_label = 'Fundraiser Details',
       description = 'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, October 26, 5:00-9:00 PM. The Boosters receive 15% of net sales. Please mention McNeil Football at the register. That is what tells them your purchase counts. Ordering in the Raising Cane''s app or at raisingcanes.com? Enter code RCFUND96 at checkout. Kiosk, catering and gift card purchases do not count. Wear your Mav shirt. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-raising-canes-2026-10-26';

update events
   set description = 'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, November 9, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-raising-canes-2026-11-09';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'spirit-night-raising-canes-2026-10-26'
     and status = 'published'
     and starts_at = timestamptz '2026-10-26 17:00 America/Chicago'
     and ends_at   = timestamptz '2026-10-26 21:00 America/Chicago'
     and signup_url like 'https://raisingcanescommunity.com/event/ccbc5242%'
     and signup_label = 'Fundraiser Details'
     and description like '%5:00-9:00 PM%'
     and description like '%15% of net sales%'
     and description like '%RCFUND96%'
     and description like '%mention McNeil Football at the register%'
     and description like '%Wear your Mav shirt%'
     and description not like '%buy one there%'
     and description not like '%5:00-8:00%';
  if n <> 1 then raise exception 'Oct 26 row not as intended'; end if;

  select count(*) into n from events
   where slug = 'spirit-night-raising-canes-2026-11-09'
     and ends_at = timestamptz '2026-11-09 20:00 America/Chicago'
     and signup_url is null
     and description like '%mention McNeil Football at the register%'
     and description like '%Wear your Mav shirt%'
     and description not like '%buy one there%'
     and description not like '%RCFUND96%';
  if n <> 1 then raise exception 'Nov 9 row not as intended'; end if;

  -- The other three spirit nights still carry the full 193 copy, untouched.
  select count(*) into n from events
   where slug in ('spirit-night-the-league-2026-09-14','spirit-night-mighty-fine-2026-09-30','spirit-night-pok-e-jos-2026-10-14')
     and description like '%you can buy one there%' and signup_url is null;
  if n <> 3 then raise exception 'a non-Cane''s spirit night changed (%)', n; end if;
end $$;

commit;

-- 113_program_ad_closed_for_season.sql
--
-- The game-day program has gone to print. Sponsors can no longer buy space in
-- it, so the "Program Ad" add-on must stop being offered on /boosters/sponsor.
-- Jeremy confirmed 2026-08-04: "we can't get sponsors in the program any
-- longer. that deadline did pass."
--
-- The card was still live and still reading "Commit by July 31 to make this
-- season's program", i.e. advertising a closed window with a date four days in
-- the past. A business could have clicked "Add This Add-On" and committed money
-- for something we cannot deliver.
--
-- DEACTIVATED, NOT DELETED. Same reasoning as migration 111 (Rudy's): every
-- public sponsor/tier query filters `.eq('active', true)`, so active=false is
-- equivalent to gone on the site while the row, its price_display, and its
-- description survive for next season. Program ads come back every year; a
-- fresh INSERT next season is how you end up with duplicate concepts (see the
-- 041/094 Rudy's history). Reactivate this row instead.
--
-- SCOPE: this touches ONE add-on row. It does NOT touch the Blue -> MVP base
-- ladder, and it does NOT touch the Tunnel or Scoreboard add-ons, which are
-- both still sellable. The Add-Ons section on /boosters/sponsor keeps rendering
-- with those two.
--
-- NOT IN SCOPE, already self-cleaned (verified 2026-08-04, no action needed):
--   - The "Senior Shoutouts" hero carousel tile had expires_at 2026-08-01 and is
--     already hidden by the expiry filter in lib/queries/hero.ts.
--   - The "Reserve a Senior Shoutout" event starts_at is 2026-08-01 04:59Z
--     (= Jul 31 11:59 PM CDT), so /events already lists it under Past.
--   Those are the separate $25 parent-facing senior ad, not this sponsor add-on.
--
-- STILL TO DO OUTSIDE THIS MIGRATION: the live sponsorship Google Form's
-- "Add-ons (optional)" question still offers three Program Ad choices
-- ($100 / $150 / $250). A migration cannot reach a Google Form. Run
-- `removeProgramAdChoices` in MavericksWebsite/scripts/update-sponsor-form-assets.gs
-- as mcneilfootballboosters@gmail.com. Until that runs, the form can still take
-- a program-ad order that the site no longer advertises.

begin;

-- Guard: fail loudly if the row isn't where we think it is, rather than
-- reporting success after updating zero rows.
do $$
declare
  n int;
begin
  select count(*) into n
  from sponsorship_tiers
  where year = '2026-27' and is_addon and name = 'Program Ad' and active;

  if n <> 1 then
    raise exception
      'Expected exactly 1 active 2026-27 Program Ad add-on row, found %. Aborting.', n;
  end if;
end $$;

update sponsorship_tiers
set active = false
where year = '2026-27'
  and is_addon
  and name = 'Program Ad';

commit;

-- Verification (expect: Tunnel t, Scoreboard t, Program Ad f):
--   select name, active from sponsorship_tiers
--   where year='2026-27' and is_addon order by sort_order;
--
-- /boosters/sponsor is force-dynamic, so this goes live with no deploy.

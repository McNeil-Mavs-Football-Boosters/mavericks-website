-- 160_sponsorship_levels_closed.sql
--
-- Kendra closed the named sponsorship levels for the season (Jeremy, 2026-08-25):
-- "platinum, gold, blue, diamond, mvp sponsorship levels shut down... she just
-- wants flexible and add-ons at this point." The Google Form has already been
-- updated on her side.
--
-- ⚠️ THE CARDS MUST KEEP RENDERING. Jeremy: "don't remove the cards though.
-- likely re-enable next summer." That is why this adds a THIRD state instead of
-- reusing the two that already exist:
--     active   = false  -> row is retired, disappears everywhere
--     sellable = false  -> display-only grouping tier (migration 122), gone
--                          from the sign-up ladder entirely
--     available = false -> NEW. Card still renders, priced and with its perks,
--                          but the call to action is dead and it is labelled
--                          "No longer available".
-- Using active/sellable here would have deleted the cards off the page, which
-- is the opposite of the ask.
--
-- Left AVAILABLE on purpose: Custom (price_flexible, the "flexible" Kendra
-- wants), Tunnel and Scoreboard (add-ons). Program Ad is already active=false
-- and is not touched here -- it went off on its own July 31 deadline.
--
-- The badge is NOT written into badge_label. The page derives the "No longer
-- available" tag from this column, so the column is the single source of truth
-- and re-opening a level is one UPDATE with no label cleanup. Platinum KEEPS
-- its 'Recommended' badge_label in the data; the page suppresses it while the
-- tier is unavailable and it comes back on its own when the tier reopens.
--
-- Default is TRUE so next season's tier rows are purchasable without anyone
-- remembering this migration existed.

begin;

alter table sponsorship_tiers
  add column if not exists available boolean not null default true;

comment on column sponsorship_tiers.available is
  'False = card still renders but cannot be purchased and shows "No longer available". Distinct from active (retired) and sellable (display-only grouping tier).';

update sponsorship_tiers
set available = false
where year = '2026-27'
  and name in ('Blue', 'Gold', 'Platinum', 'Diamond', 'MVP');

-- Guard: exactly the five named levels closed, and the three Kendra wants left
-- open must still be open. Fails the transaction rather than half-applying.
do $$
declare
  closed int;
  open_wanted int;
begin
  select count(*) into closed
  from sponsorship_tiers
  where year = '2026-27' and available = false;

  select count(*) into open_wanted
  from sponsorship_tiers
  where year = '2026-27'
    and name in ('Custom', 'Tunnel', 'Scoreboard')
    and available = true;

  if closed <> 5 then
    raise exception 'expected 5 closed levels, found %', closed;
  end if;
  if open_wanted <> 3 then
    raise exception 'expected Custom/Tunnel/Scoreboard open, found %', open_wanted;
  end if;
end $$;

commit;

-- 163_reopen_blue_tier.sql
--
-- Kendra wants the Blue level ($500) selling again (Jeremy, 2026-08-25). This is
-- a partial reversal of 160, which closed Blue, Gold, Platinum, Diamond and MVP
-- the same day.
--
-- This is exactly the flip 160 was designed for: `available` is a normal data
-- column, so reopening a level is one UPDATE with no cleanup. Nothing has to be
-- un-said in `badge_label` because the "No longer available" tag was never
-- written there -- the page derives it from this column.
--
-- Gold, Platinum, Diamond and MVP stay closed and keep their greyed-out cards.
-- Platinum still holds its 'Recommended' badge_label in the data; it stays
-- suppressed while Platinum is closed and returns by itself if it reopens.
--
-- ⚠️ No deploy needed. /boosters/sponsor is `dynamic = "force-dynamic"`, so this
-- is live on commit. That is NOT true of a `lib/constants.ts` change.

begin;

update sponsorship_tiers
set available = true
where year = '2026-27' and name = 'Blue';

do $$
declare open_names text; closed_count int;
begin
  select string_agg(name, ', ' order by sort_order) into open_names
  from sponsorship_tiers
  where year = '2026-27' and active and sellable and available;

  select count(*) into closed_count
  from sponsorship_tiers
  where year = '2026-27' and active and sellable and not available;

  -- Blue joins Custom, Tunnel and Scoreboard; four named levels stay closed.
  if open_names is distinct from 'Blue, Custom, Tunnel, Scoreboard' then
    raise exception 'unexpected open set: %', open_names;
  end if;
  if closed_count <> 4 then
    raise exception 'expected 4 closed levels, got %', closed_count;
  end if;
end $$;

commit;

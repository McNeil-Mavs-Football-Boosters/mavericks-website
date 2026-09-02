-- 179_whataburger_platinum.sql
--
-- Whataburger moves GOLD -> PLATINUM. Jeremy 2026-09-01.
--
-- ⚠️ PLATINUM IS CLOSED FOR THE SEASON (`available = false`, migration 160) AND
-- THIS MUST NOT REOPEN IT. Adding or promoting a sponsor at a closed level is
-- normal and already established by 164, which added three Gold sponsors while
-- Gold was closed: the roster surfaces filter tier `active`, not `available`, so
-- the card publishes fine while the level stays unsellable. That is the correct
-- state for a sponsor who has committed at that level. This migration asserts
-- Platinum is STILL closed when it finishes.
--
-- ── SORT ORDER IS RECOMPUTED, NOT HAND-SHIFTED ──
-- `sponsors.sort_order` is ONE GLOBAL SEQUENCE encoding tier-then-alphabetical.
-- Promoting Whataburger moves it from the end of Gold (13) to the end of
-- Platinum, which shifts every Gold row down one. 154, 164 and 167 all recompute
-- the whole sequence from `tier price_cents DESC, name` rather than nudging rows;
-- this does the same. Expected result: Platinum 1-4 (Airborne, Capstone, North
-- Austin Oral Surgery, Whataburger), Gold 5-12, Blue 13-17.
--
-- Community partners stay at sort_order 0 and are sorted by name at query time,
-- so the recompute is scoped to kind = 'sponsor'.
--
-- ⚠️ Whataburger's logo is the full-colour lockup uploaded by 169
-- (`whataburger-r2.png`), NOT the white nav asset they originally sent, which
-- rendered as a blank rectangle on the white cards. Platinum draws logos LARGER
-- (200x72 box vs Gold's 150x58), so this promotion makes that earlier fix more
-- visible, not less. Nothing to do, but do not swap the asset back.
--
-- DB-ONLY, NO DEPLOY. /sponsors and /boosters/sponsor are force-dynamic; the
-- homepage strip picks it up after its ISR minute.
--
-- Rollback: 179_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.name = 'Whataburger' and t.name = 'Gold';
  if n <> 1 then raise exception 'Whataburger is not currently a Gold sponsor (found %)', n; end if;

  select count(*) into n from sponsors where year = '2026-27' and kind = 'sponsor';
  if n <> 18 then raise exception 'expected 18 paying sponsors, found %', n; end if;
end $$;

update sponsors
   set tier_id = (select id from sponsorship_tiers where year = '2026-27' and name = 'Platinum'),
       updated_at = now()
 where year = '2026-27' and name = 'Whataburger';

-- Recompute the whole paid sequence: tier price descending, then name.
with ranked as (
  select s.id,
         row_number() over (order by t.price_cents desc, s.name) as rn
    from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor'
)
update sponsors s
   set sort_order = ranked.rn, updated_at = now()
  from ranked
 where s.id = ranked.id and s.sort_order is distinct from ranked.rn;

do $$
declare n int; v text;
begin
  select count(*) into n from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.name = 'Whataburger' and t.name = 'Platinum';
  if n <> 1 then raise exception 'Whataburger did not move to Platinum'; end if;

  select count(*) into n from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor' and t.name = 'Platinum';
  if n <> 4 then raise exception 'expected 4 Platinum sponsors, found %', n; end if;

  -- 🚨 The promotion must NOT have reopened the level for sale.
  select count(*) into n from sponsorship_tiers
   where year = '2026-27' and name = 'Platinum' and available = false;
  if n <> 1 then raise exception 'Platinum is no longer closed; 179 must not reopen a tier'; end if;

  -- Dense 1..18 with no gaps or duplicates.
  select count(*) into n from (
    select sort_order from sponsors where year='2026-27' and kind='sponsor'
     group by sort_order having count(*) > 1) d;
  if n <> 0 then raise exception '% duplicate sort_order values', n; end if;

  select string_agg(s.name, ', ' order by s.sort_order) into v
    from sponsors s join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.kind = 'sponsor' and t.name = 'Platinum';
  raise notice 'Platinum now: %', v;
end $$;

commit;

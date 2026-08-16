-- 147_retire_stadiums_section.sql
--
-- Retires the "Stadiums & Directions" section of /resources. Jeremy 2026-08-16,
-- and it is a consequence of the venue work rather than a preference: every game
-- on the site now carries its own verified pin (migrations 134-146), so a
-- hand-maintained list of three stadium links is strictly worse than the thing
-- next to the game itself. It also had the failure mode this whole day was about
-- - the list is only correct for the stadiums someone remembered to add.
--
-- Two of the three rows were demonstrably stale already:
--   'Dragon Stadium' pointed at 300 N Lake Creek Dr, the address migration 135
--   REJECTED in favour of 201 Deep Wood Dr once Jeremy sent the real pin.
--   'House Park' is not on the 2026-27 schedule at all; it is a 2025-26 venue.
-- Only KRAC was still right, and KRAC now has a verified pin on every row that
-- plays there.
--
-- DEACTIVATED, NOT DELETED - same treatment as migrations 111 and 113. If the
-- section ever comes back the rows are recoverable, and `active = false` is what
-- getResourceLinks already filters on, so this needs no code to take effect.
--
-- ⚠️ The `resource_links.section` ENUM keeps its 'stadiums' value. Dropping an
-- enum value is a rewrite of the column's type for three dead rows, and Postgres
-- cannot drop one in-place anyway. The page-side guard is that any link whose
-- section is not in SECTION_ORDER now falls into "Other" rather than vanishing -
-- so if someone adds a stadiums row later it appears somewhere visible instead
-- of being silently dropped.
--
-- The clear bag policy is NOT a row here and is unaffected: it lives in
-- lib/constants.ts (CLEAR_BAG_POLICY_URL), shared with both games pages, and
-- moves in the same commit from a footnote under Stadiums to an entry under
-- Resources.

begin;

update resource_links
   set active = false
 where section = 'stadiums' and active = true;

do $$
declare n int;
begin
  select count(*) into n from resource_links where section = 'stadiums' and active = true;
  if n <> 0 then raise exception '% stadiums links still active', n; end if;

  select count(*) into n from resource_links where section = 'stadiums';
  if n <> 3 then raise exception 'expected 3 archived stadiums rows, got %', n; end if;

  -- Nothing else may have been touched.
  select count(*) into n from resource_links where section <> 'stadiums' and active = true;
  if n <> 12 then raise exception 'expected 12 active non-stadium links, got %', n; end if;
end $$;

commit;

-- /resources is force-dynamic: live with no deploy (the code change ships with it).

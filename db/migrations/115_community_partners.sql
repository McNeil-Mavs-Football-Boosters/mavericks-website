-- 115_community_partners.sql
--
-- Community Partners: businesses that give in-kind support (meals, gift cards,
-- product) rather than buying a sponsorship level. They get acknowledged with a
-- logo and a link on /boosters/donate, and are NOT sold as a tier.
--
-- Jeremy 2026-08-08, replacing the earlier "Friends level" idea. The point of
-- moving them to the donate page is that they never imply a purchased level.
--
-- ⚠️ ACKNOWLEDGMENT, NOT ADVERTISING. The club is a 501(c)(3). Under the
-- qualified-sponsorship rules, showing a partner's name, logo and a plain link
-- is acknowledgment; adding promotional language (taglines, discounts, offers,
-- qualitative claims, calls to action) turns it into advertising income. The
-- render deliberately carries NO description/tagline field for that reason —
-- do not add one. Also do NOT publish a dollar value for an in-kind gift;
-- valuing it is the donor's job for their own return, not ours.
--
-- ── DESIGN: one explicit column, not an inferred marker ──
-- `kind` discriminates instead of leaning on `tier_id IS NULL`. There are
-- currently ZERO untiered sponsors, so a null tier means "someone forgot to
-- pick one" and it should keep meaning exactly that. Inferring partner-ness
-- from a missing value would make a data-entry slip silently publish a paying
-- sponsor in the wrong place.
--
-- ⚠️ EVERY sponsor-facing surface must filter `kind = 'sponsor'`. There are
-- three (app/page.tsx, app/sponsors/page.tsx, app/boosters/sponsor/page.tsx).
-- Miss one and a partner renders as a paying sponsor — which is precisely the
-- Rudy's failure this project already shipped twice (041 seeded it as a
-- placeholder, 060 removed it, 094 re-added it on a bad confirmation, 106
-- carried it forward, 111 finally deactivated it).
--
-- ── RUDY'S: the row is CONVERTED, never re-inserted ──
-- Rudy's has now genuinely agreed to provide meals (Jeremy 2026-08-08), so they
-- are a real Community Partner. Migration 111's note says explicitly: "Don't
-- write a fresh INSERT — that's how this ended up duplicated in concept across
-- 041/094." So this reuses the existing 2026-27 row, preserving its id and
-- created_at, and flips it from a deactivated MVP sponsor to an active partner.
--
-- The 2025-26 row is deliberately LEFT INACTIVE. Rudy's was never a sponsor in
-- that season and is not retroactively a partner either.

begin;

alter table sponsors
  add column if not exists kind text not null default 'sponsor';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'sponsors_kind_check'
  ) then
    alter table sponsors
      add constraint sponsors_kind_check
      check (kind in ('sponsor', 'community_partner'));
  end if;
end $$;

comment on column sponsors.kind is
  'sponsor = bought a sponsorship level, renders on /sponsors + the homepage strip. '
  'community_partner = in-kind support (meals, gift cards), renders ONLY on '
  '/boosters/donate. Every sponsor-facing query must filter kind = ''sponsor''.';

-- Guard: fail loudly rather than silently updating zero rows.
do $$
declare
  n int;
begin
  select count(*) into n
  from sponsors
  where year = '2026-27' and name = 'Rudy''s BBQ';

  if n <> 1 then
    raise exception
      'Expected exactly 1 Rudy''s BBQ row for 2026-27, found %. Aborting.', n;
  end if;
end $$;

update sponsors
set kind       = 'community_partner',
    tier_id    = null,   -- was MVP; a partner has no purchased level
    active     = true,   -- 111 deactivated it; they are now real
    sort_order = 1
where year = '2026-27'
  and name = 'Rudy''s BBQ';

commit;

-- Verification:
--   select name, year, kind, active, tier_id, sort_order
--   from sponsors where name ilike '%rud%' order by year;
--     -> 2025-26 : sponsor / inactive  (untouched)
--     -> 2026-27 : community_partner / active / tier_id NULL
--
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 6, community_partner 1
--
-- /boosters/donate is ISR revalidate=300, so allow ~5 min. /sponsors and
-- /boosters/sponsor are force-dynamic and update immediately.

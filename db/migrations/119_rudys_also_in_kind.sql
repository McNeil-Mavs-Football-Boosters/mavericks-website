-- 119_rudys_also_in_kind.sql
--
-- Rudy's BBQ is BOTH: a paying Scoreboard sponsor ($3,000 / two seasons) AND an
-- in-kind supporter providing meals. Jeremy confirmed 2026-08-08, answering the
-- question migration 117 deliberately left open.
--
-- ── WHY A SECOND COLUMN AND NOT A SECOND ROW ──
-- `kind` is single-valued, so expressing "both" needs something. The options
-- were a duplicate sponsors row, widening `kind`, or a separate flag.
--
-- A duplicate row was rejected outright. This is the single most churned row in
-- the database (041 seed → 060 remove → 094 re-add → 106 carry → 111 deactivate
-- → 115 partner → 117 sponsor), and every prior mess came from the concept
-- existing in more than one place at once. Two live Rudy's rows would mean two
-- things to keep in sync and two things to forget.
--
-- So: `kind` keeps meaning "what did this business BUY" — the thing that decides
-- whether they belong on the sponsor surfaces — and the new flag records the
-- separate fact that they also give in kind. One row, two orthogonal facts.
--
-- Effect: Rudy's renders on /sponsors + the homepage carousel as a Scoreboard
-- sponsor (unchanged), AND in Community Partners on /boosters/donate.
-- Partners go 7 -> 8.
--
-- ⚠️ The three sponsor surfaces still filter `kind = 'sponsor'` and must NOT be
-- taught about this flag. A community_partner must never leak onto them; this
-- flag only ever ADDS a business to the donate page.

begin;

alter table sponsors
  add column if not exists provides_in_kind boolean not null default false;

comment on column sponsors.provides_in_kind is
  'TRUE when this business also gives in-kind support (meals, gift cards) on top '
  'of whatever `kind` says they bought. Community Partners on /boosters/donate = '
  'kind = ''community_partner'' OR provides_in_kind. Independent of `kind`: a '
  'paying sponsor can be both, which is why this is not another `kind` value.';

do $$
declare n int;
begin
  select count(*) into n from sponsors
  where year = '2026-27' and name = 'Rudy''s BBQ' and kind = 'sponsor';
  if n <> 1 then
    raise exception 'Expected 1 Rudy''s sponsor row for 2026-27, found %', n;
  end if;
end $$;

update sponsors
set provides_in_kind = true
where year = '2026-27' and name = 'Rudy''s BBQ';

commit;

-- Verification:
--   select name, kind, provides_in_kind from sponsors
--   where year='2026-27' and active and (kind='community_partner' or provides_in_kind)
--   order by name;
--     -> 8 rows: the 7 partners plus Rudy's (kind=sponsor, provides_in_kind=t)
--
--   select count(*) from sponsors where year='2026-27' and active and kind='sponsor';
--     -> still 8; the sponsor surfaces are unaffected

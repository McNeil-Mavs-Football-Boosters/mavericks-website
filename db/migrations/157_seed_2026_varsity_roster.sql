-- 157_seed_2026_varsity_roster.sql
--
-- Seed the 45-player 2026-27 VARSITY roster. Source: "Varsity McNeil Roster
-- 2026.xlsx", sheet "Var Roster 821", handed over by the coaching staff and
-- given to Claude by Jeremy 2026-08-24. This is the long-open item from
-- booster_club_info.md ("get the 2026-27 rosters from the coaching staff").
--
-- DB-ONLY, NO DEPLOY. current_roster_year is ALREADY '2026-27' (migration 095,
-- applied 2026-07-28), and /roster/varsity has been rendering its "Coming Soon"
-- empty state against the player-less stub row that 057 created. Neither roster
-- page exports `dynamic` or `revalidate` and neither has generateStaticParams,
-- so they render on demand and this goes live the moment it commits.
--
-- ⚠️ VARSITY ONLY. The same workbook carries a "JV Roster 821" sheet, but it has
-- NO jersey numbers at all and Jeremy asked for the varsity roster. /roster/jv
-- keeps its Coming Soon state. Do not seed JV from that sheet without deciding
-- what to do about the missing numbers.
--
-- ⚠️ The freshman Blue row is active = false since 148. Not touched here.
--
-- ── DECISIONS MADE ABOUT THE SOURCE DATA ──
--
-- 1. GRADE. The sheet stores CLASS as 12/11/10. Stored here as 'Sr.'/'Jr.'/'So.'
--    with the trailing period, because PlayerTable renders grade verbatim with
--    no mapping table and all 111 existing player rows use that form. Storing
--    "12" would put a bare number in a column that reads "Sr." everywhere else.
--
-- 2. NAME SPLIT. First token = first_name, everything after = last_name, which
--    is the rule every prior seed follows. That gives 'Aymane' / 'El Anssari'
--    -- byte-identical to how 031 already stored the same player on JV -- and
--    'Jerrion' / 'Gary Darks'.
--    ONE deliberate exception, spelled out rather than detected: Amery A.
--    Schoepflin is stored 'Amery A.' / 'Schoepflin', because "A." is a middle
--    initial and not a surname. Precedent for a multi-token first_name is
--    031's ('7','Ja Corian','Hubbard'). PlayerTable interpolates
--    "{first} {last}", so the rendered name is identical either way; this is
--    about the column meaning something.
--    ⚠️ Do NOT replace this with a middle-initial detector. There is exactly one
--    such row and a guesser would be wrong the first time a surname is an
--    initial.
--
-- 3. JERSEY NUMBERS ARE TEXT AND SOME ARE DUAL. '(5/2)', '(8/18)', '(9/10)',
--    '64/65' and '84/80' are stored exactly as the sheet has them, parentheses
--    and all. The notation is inconsistent in the source (three parenthesised,
--    two not) and that inconsistency is preserved -- it is the coaches' data,
--    and normalising it would make the site disagree with the printed roster
--    and the PDF. jersey_number is text precisely for this (013).
--    Consequence to know about: PlayerTable's client-side jersey sort parses
--    the string to a number and sends anything non-numeric to +Infinity. That
--    never fires here because sort_order is the PRIMARY key of the sort and is
--    dense 1..45 below, but it is why sort_order must not be left at its 0
--    default.
--
-- 4. SORT ORDER is the sheet's own reading order: left block top-to-bottom
--    interleaved with the right block, which is jersey-ascending across both.
--    Dense 1..45, no gaps.
--
-- 5. POSITIONS ARE VERBATIM, including 'DL/ LB' with the stray space after the
--    slash (row 25, right block). Same rule 031 used when it preserved 'WIlliams'
--    and 'Deshay' from its source. If the staff want it cleaned up, that is a
--    follow-up UPDATE with their say-so, not a silent fix here.
--
-- 6. HEIGHT AND WEIGHT ARE NULL. The sheet does not carry them. PlayerTable
--    renders an em dash for both. NULL::int on weight is required -- it types
--    the column in the VALUES list.
--
-- 7. rosters.body IS LEFT EMPTY. The sheet's staff credit block (head coach,
--    assistants, trainers, principal, athletic director) is NOT copied into it,
--    because it contradicts the live /coaches page: this sheet says Athletic
--    Director is Jeff Cheatham, while 055 and 062 have Jerry Gardner as "Head
--    Coach and Athletic Director". Publishing both would put the site in
--    disagreement with itself. Unresolved as of 2026-08-24 -- the credit block
--    does appear on the downloadable PDF, which is a verbatim reproduction of
--    what the coaches sent.
--
-- No duplicate jersey numbers, no missing positions, no missing grades --
-- checked across all 45 rows before writing this.
--
-- Rollback: 157_rollback.sql

begin;

-- Guard the starting state. If the stub roster row is missing, or players have
-- already been loaded, stop rather than double-seed. 038's cleanup note and
-- 029's "cleanup path" comment both exist because a re-run is otherwise silent.
do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity'
     and team_designation is null and active = true;
  if n <> 1 then
    raise exception 'expected exactly 1 active 2026-27 varsity roster row, found %', n;
  end if;

  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if n <> 0 then
    raise exception '2026-27 varsity roster already has % player rows - not re-seeding', n;
  end if;
end $$;

-- Resolve the roster row by its natural key inside the statement, so no id
-- literal is hardcoded and the insert cannot land on the wrong roster.
insert into players (
  roster_id,
  jersey_number, first_name, last_name,
  position, grade, height, weight,
  sort_order, active
)
select
  r.id,
  v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, null, null::int,
  v.sort_order, true
from rosters r
cross join (values
  ('0'     , 'Tyson'    , 'Cox'         , 'LB'    , 'Sr.',  1),
  ('26'    , 'Derrick'  , 'Williams'    , 'DL'    , 'Jr.',  2),
  ('1'     , 'Isaiah'   , 'Jones'       , 'DB'    , 'Sr.',  3),
  ('27'    , 'Eli'      , 'Weaver'      , 'DB'    , 'Sr.',  4),
  ('3'     , 'Conan'    , 'Shin'        , 'DB'    , 'So.',  5),
  ('28'    , 'Tramaurie', 'Mayweather'  , 'RB'    , 'Sr.',  6),
  ('4'     , 'Jerrion'  , 'Gary Darks'  , 'DB'    , 'Sr.',  7),
  ('29'    , 'Aymane'   , 'El Anssari'  , 'K'     , 'Sr.',  8),
  ('(5/2)' , 'Zylen'    , 'Hall'        , 'RB'    , 'Sr.',  9),
  ('30'    , 'Quamere'  , 'Southernland', 'DL'    , 'Sr.', 10),
  ('6'     , 'Ade'      , 'Carter'      , 'WR'    , 'So.', 11),
  ('32'    , 'Jordan'   , 'Deshay'      , 'TE/HB' , 'Sr.', 12),
  ('7'     , 'Tremaine' , 'Memminger'   , 'DB'    , 'Jr.', 13),
  ('33'    , 'Michael'  , 'Sieber'      , 'K'     , 'Sr.', 14),
  ('(8/18)', 'Kaden'    , 'Kearney'     , 'DB/RB' , 'Jr.', 15),
  ('34'    , 'Akmal'    , 'Waqif'       , 'LB'    , 'Jr.', 16),
  ('(9/10)', 'Ford'     , 'Askins'      , 'DL'    , 'Sr.', 17),
  ('35'    , 'Ciecero'  , 'Stroman'     , 'DL'    , 'Jr.', 18),
  ('11'    , 'Orion'    , 'Covault'     , 'QB'    , 'Sr.', 19),
  ('38'    , 'Kieran'   , 'Jalbert'     , 'LB'    , 'Jr.', 20),
  ('12'    , 'Kees'     , 'Glinski'     , 'HB'    , 'Sr.', 21),
  ('40'    , 'Asher'    , 'Johnson'     , 'DB'    , 'Sr.', 22),
  ('13'    , 'Aiden'    , 'Creque'      , 'WR'    , 'Sr.', 23),
  ('51'    , 'Preston'  , 'Higgins'     , 'OL'    , 'Jr.', 24),
  ('14'    , 'Jeremy'   , 'Powell'      , 'WR/QB' , 'So.', 25),
  ('52'    , 'Zackary'  , 'Hauser'      , 'OL'    , 'Sr.', 26),
  ('15'    , 'Lucas'    , 'Rosilmo'     , 'DB'    , 'Sr.', 27),
  ('55'    , 'Ethan'    , 'Nguyen'      , 'DL'    , 'Sr.', 28),
  ('16'    , 'Quincy'   , 'Sampson'     , 'WR'    , 'Jr.', 29),
  ('61'    , 'Gianni'   , 'Aviles'      , 'DL'    , 'Sr.', 30),
  ('17'    , 'Treyvon'  , 'Cargill'     , 'WR'    , 'So.', 31),
  ('64/65' , 'Jace'     , 'Hicks'       , 'OL'    , 'So.', 32),
  ('19'    , 'Garrett'  , 'Root'        , 'TE/HB' , 'Sr.', 33),
  ('66'    , 'Kaeden'   , 'Frazier'     , 'DL/OL' , 'So.', 34),
  ('20'    , 'Owen'     , 'Mazorra'     , 'WR/DB' , 'Jr.', 35),
  ('71'    , 'Favour'   , 'Omagbon'     , 'OL'    , 'So.', 36),
  ('21'    , 'Evan'     , 'Vest'        , 'DB'    , 'Sr.', 37),
  ('72'    , 'Daniel'   , 'Christensen' , 'OL'    , 'Jr.', 38),
  ('22'    , 'Mcharo'   , 'Criswell'    , 'RB'    , 'Sr.', 39),
  ('75'    , 'Wesley'   , 'Davis'       , 'OL'    , 'Jr.', 40),
  ('23'    , 'James'    , 'Evans'       , 'DL'    , 'Sr.', 41),
  ('76'    , 'Kyle'     , 'Rayburn'     , 'OL'    , 'Jr.', 42),
  ('25'    , 'Jacob'    , 'Machado'     , 'WR'    , 'Jr.', 43),
  ('84/80' , 'Amery A.' , 'Schoepflin'  , 'TE/HB' , 'Sr.', 44),
  ('90'    , 'Jesus'    , 'Galaza'      , 'DL/ LB', 'Sr.', 45)
) as v(jersey_number, first_name, last_name, position, grade, sort_order)
where r.year = '2026-27'
  and r.team_level = 'varsity'
  and r.team_designation is null
  and r.active = true;

-- source_note is invisible once players exist -- app/roster/[level]/page.tsx
-- only reads it for the Coming Soon subline -- so this is provenance for the
-- next person, not display copy.
--
-- pdf_storage_path turns the Print View button back on. It has been NULL for
-- 2026-27 since 095 flipped the year and silently unlinked the 2025-26 PDFs;
-- PrintViewLink renders nothing at all on NULL, which is why it just vanished
-- rather than 404ing.
--
-- ⚠️ THE VALUE IS BUCKET-PREFIXED. lib/storage.ts publicObjectUrl() builds
-- /storage/v1/object/public/${path}, so the leading 'documents/' is part of the
-- stored string, not something the helper adds.
--
-- The object was uploaded to documents/rosters/varsity-2026.pdf and fetched
-- back byte-identical BEFORE this line was written -- 040 exists purely because
-- a path was written that did not match the object name (singular 'freshman'
-- vs the plural object). Do not write this UPDATE against a path you have not
-- actually GET'd.
update rosters
   set source_note = 'Varsity roster provided by the McNeil coaching staff, received 2026-08-24',
       pdf_storage_path = 'documents/rosters/varsity-2026.pdf'
 where year = '2026-27'
   and team_level = 'varsity'
   and team_designation is null;

-- Count, then assert. 45 players on exactly one roster row.
do $$
declare n int;
begin
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null and p.active = true;
  if n <> 45 then
    raise exception 'expected 45 varsity players after seed, found %', n;
  end if;

  select count(distinct p.sort_order) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and r.team_designation is null;
  if n <> 45 then
    raise exception 'sort_order is not unique across the 45 rows (% distinct)', n;
  end if;
end $$;

commit;

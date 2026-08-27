-- 168_seed_2026_freshman_roster.sql
--
-- Seed the 49-player 2026-27 FRESHMAN roster. Sources: 
-- "2026_McNeil_Freshman_Football_Roster.xlsm" AND its PDF export, both from the
-- coaching staff, given to Claude by Jeremy 2026-08-26. This completes the
-- 2026-27 rosters: varsity (157-159), JV (166), freshman (here).
--
-- ✅ TWO SOURCES, CROSS-CHECKED, AND THEY AGREE EXACTLY. The workbook was parsed
-- by cell and the PDF independently by column position; both produced the same
-- 49 (jersey, name) pairs. That is why this one carries no "verbatim vs typo"
-- hedging -- anything odd below is odd in both files.
--
-- ⚠️ ONE FRESHMAN TEAM THIS SEASON. `freshman_has_blue` is false (migration 148)
-- and the Blue roster row is active = false. This seeds ONLY the Green row,
-- which is the surviving default; the URL keeps /green while every user-visible
-- label reads plain "Freshmen". Do not seed Blue.
--
-- DB-ONLY, NO DEPLOY.
--
-- ── DECISIONS ABOUT THE SOURCE DATA ──
--
-- 1. ⚠️ THERE IS NO POSITION COLUMN, AND NO GRADE, HEIGHT OR WEIGHT EITHER. The
--    roster is TWO columns: # and PLAYER. That is everything the staff sent.
--    **So four of the six columns on /roster/freshman/green render as
--    em-dashes.** Last season's freshman roster had positions, so this is a
--    regression in what the staff supply, not in what the site can show.
--    Inventing positions is out of the question and inferring them from jersey
--    number would be a guess dressed as data. Asked for, not assumed.
--    See the followups entry about suppressing all-empty columns -- that is a UI
--    change and is deliberately NOT bundled into this data migration.
--
-- 2. PARSED BY COLUMN POSITION AND BY VALUE, NOT BY ROW INDEX. Two traps here,
--    both hit during this work:
--      * The PDF is TWO PAGES and page 2 has NO repeated header, so its rows
--        start at the very top of the page. A y-threshold tuned to page 1 threw
--        away 13 of the 49 silently. Jersey cells are now identified by being
--        digits, and header cells by their text.
--      * The workbook has a BLANK ROW 3, so the header is row 4 and data starts
--        at row 5, not row 4. A hardcoded min_row swallowed the header as if it
--        were a player. Rows are now taken only where the jersey cell is
--        actually numeric.
--
-- 3. SORT ORDER IS JERSEY ASCENDING, dense 1..49 -- 159's rule, applied up front.
--
-- 4. NAME SPLIT IS THE UNIFORM RULE: first token = first_name, rest = last_name.
--    Every name here is exactly two tokens, so unlike JV (166) there is not a
--    single ambiguous row. The three hyphenated surnames (Al-Rikabi,
--    Pruitt-Burkett, Rivera-Lara) are single tokens and need no special care.
--
-- 5. ⚠️ CURLY APOSTROPHES NORMALISED TO STRAIGHT, and this IS a deliberate
--    exception to the verbatim rule. The workbook has Ja'Qualieon Thomas and
--    A'Manuel Johnson with U+2019, which is Excel autocorrect, not a spelling
--    choice by the coaches. **All six apostrophes already in `players` are
--    straight and none is curly** -- checked, not assumed -- so importing curly
--    ones would split the convention inside one table for no gain. This is the
--    same category as the trailing space 166 trimmed: character normalisation,
--    not spelling. Spellings themselves are untouched: "Sclok Patel" and
--    "Authur Edison" appear that way in BOTH sources and are left alone.
--
-- 6. PRINT VIEW USES THE STAFF'S OWN PDF EXPORT, uploaded as-is to
--    documents/rosters/freshman-2026.pdf (21,261 bytes, sha256-identical after
--    the round trip, fetches 200 as application/pdf). Nothing re-typeset.

begin;

insert into players (roster_id, jersey_number, first_name, last_name, sort_order, active)
select r.id, v.jersey, v.first, v.last, v.ord, true
from rosters r
cross join (values
  ('0', 'Ja''Qualieon', 'Thomas', 1),
  ('1', 'Brandal', 'Harris', 2),
  ('2', 'John', 'Foster', 3),
  ('3', 'Rocco', 'Lachance', 4),
  ('4', 'Yousif', 'Al-Rikabi', 5),
  ('5', 'A''Manuel', 'Johnson', 6),
  ('6', 'Wayne', 'Svede', 7),
  ('7', 'Alexander', 'Hopingarder', 8),
  ('8', 'Sclok', 'Patel', 9),
  ('9', 'Kannin', 'Ross', 10),
  ('10', 'Henion', 'Kim', 11),
  ('11', 'Mason', 'Martinez', 12),
  ('12', 'Gashawn', 'Brown', 13),
  ('13', 'Londale', 'Harper', 14),
  ('14', 'Fabian', 'Aguero', 15),
  ('15', 'Robby', 'Bayer', 16),
  ('16', 'Alex', 'Guillen', 17),
  ('17', 'Maddex', 'Witt', 18),
  ('18', 'Anthony', 'Patschke', 19),
  ('20', 'Gavin', 'Toliver', 20),
  ('21', 'Drake', 'Thrift', 21),
  ('22', 'Darren', 'Hernandez', 22),
  ('23', 'Hannibal', 'Windler', 23),
  ('25', 'Damien', 'Martinez', 24),
  ('26', 'Joseph', 'Batrice', 25),
  ('27', 'Paxton', 'Golden', 26),
  ('28', 'Bryan', 'Diaz', 27),
  ('30', 'Quinten', 'Spurlock', 28),
  ('33', 'Gunner', 'Pruitt-Burkett', 29),
  ('48', 'Cayden', 'Minks', 30),
  ('51', 'Julian', 'Cordi', 31),
  ('52', 'James', 'Smith', 32),
  ('53', 'Ismael', 'Rivera-Lara', 33),
  ('54', 'Sebastian', 'Carmona', 34),
  ('55', 'Andre', 'Saldana', 35),
  ('56', 'Andy', 'Fernandez', 36),
  ('61', 'Dwayne', 'Carlos', 37),
  ('62', 'Authur', 'Edison', 38),
  ('63', 'Nicholas', 'Garcia', 39),
  ('64', 'Denis', 'Franco', 40),
  ('66', 'Ethan', 'Aranda', 41),
  ('68', 'William', 'Giesen', 42),
  ('70', 'Xayvion', 'Hill', 43),
  ('71', 'Nathan', 'Gonzalez', 44),
  ('72', 'Nelson', 'Galarza', 45),
  ('73', 'Dominick', 'Pisculli', 46),
  ('74', 'Adam', 'Zayad', 47),
  ('75', 'Tiago', 'Lopez', 48),
  ('88', 'Saathvik', 'Gundkanahalli', 49)
) as v(jersey, first, last, ord)
where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green'
  and not exists (select 1 from players p where p.roster_id = r.id);

update rosters
set pdf_storage_path = 'documents/rosters/freshman-2026.pdf',
    source_note = 'Freshman roster provided by the McNeil coaching staff, received 2026-08-26'
where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green';

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year='2026-27' and team_level='freshman' and team_designation='Green';
  if rid is null then raise exception 'no 2026-27 freshman Green roster row'; end if;

  select count(*) into n from players where roster_id = rid;
  if n <> 49 then raise exception 'expected 49 freshman players, found %', n; end if;

  if (select count(distinct sort_order) from players where roster_id=rid) <> 49
     or (select min(sort_order) from players where roster_id=rid) <> 1
     or (select max(sort_order) from players where roster_id=rid) <> 49 then
    raise exception 'freshman sort_order is not a dense 1..49 sequence';
  end if;

  select count(*) into n from (
    select sort_order, row_number() over (order by (jersey_number)::int) as by_jersey
    from players where roster_id = rid
  ) t where t.sort_order <> t.by_jersey;
  if n <> 0 then raise exception '% freshman rows are not in jersey order', n; end if;

  select count(*) into n from players
   where roster_id = rid and jersey_number !~ '^[0-9]+$';
  if n <> 0 then raise exception '% freshman jerseys are not plain integers', n; end if;

  -- Decision 5: no curly apostrophe may reach the table.
  select count(*) into n from players
   where roster_id = rid and (first_name || last_name) ~ U&'\2019';
  if n <> 0 then raise exception '% freshman names kept a curly apostrophe', n; end if;

  select count(*) into n from players
   where roster_id = rid and (first_name <> btrim(first_name) or last_name <> btrim(last_name));
  if n <> 0 then raise exception '% freshman rows have untrimmed whitespace', n; end if;

  -- The Blue row must stay empty and inactive (migration 148).
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level='freshman' and r.team_designation='Blue';
  if n <> 0 then raise exception 'freshman Blue was seeded; it must stay empty'; end if;

  select count(*) into n from rosters
   where id = rid and pdf_storage_path = 'documents/rosters/freshman-2026.pdf';
  if n <> 1 then raise exception 'freshman pdf_storage_path not set'; end if;

  -- Varsity and JV untouched.
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year='2026-27' and r.team_level in ('varsity','jv');
  if n <> 77 then raise exception 'varsity+JV player count changed: % (expected 77)', n; end if;
end $$;

commit;

-- 166_seed_2026_jv_roster.sql
--
-- Seed the 32-player 2026-27 JV roster. Source: "JV roster - JV Roster-Final
-- (1).pdf", from the coaching staff, given to Claude by Jeremy 2026-08-26.
-- Same treatment as the varsity roster (157/158/159), with those three
-- migrations' lessons applied up front rather than as follow-ups.
--
-- ✅ THIS CLOSES THE BLOCKER 157 RAISED. 157's header says: "The same workbook
-- carries a 'JV Roster 821' sheet, but it has NO jersey numbers at all ... Do
-- not seed JV from that sheet without deciding what to do about the missing
-- numbers." This is a DIFFERENT and later source -- a finalised PDF -- and it
-- carries a jersey number for every player. The xlsx sheet was not used.
--
-- DB-ONLY, NO DEPLOY. `current_roster_year` is already '2026-27' and
-- /roster/jv has been rendering its "Coming Soon" empty state against the
-- player-less stub row. It renders on demand, so this goes live on commit.
--
-- ── DECISIONS ABOUT THE SOURCE DATA ──
--
-- 1. PARSED BY COLUMN POSITION, NOT READING ORDER. The PDF lays the roster out
--    in two side-by-side blocks and the left and right rows are NOT vertically
--    aligned -- #0's row sits at y=90.3 while #23's sits at y=94.5, and the
--    drift grows down the page. Plain text extraction interleaves them and, in
--    three places, emits a name AFTER the position of the row below it. Tokens
--    were therefore bucketed by x into six columns and zipped within each
--    block. Verified: 16 numbers, 16 names and 16 positions in EACH block.
--
-- 2. SORT ORDER IS JERSEY ASCENDING, 1..32, dense. This is 159's correction
--    applied from the start. 157 used the sheet's two-block reading order and
--    produced 0, 26, 1, 27, ... on a single-column web page, which had to be
--    re-sorted the same day. Do not "restore" the print order here.
--    ⚠️ The PDF keeps its two-block layout and MUST NOT be regenerated to match
--    this. That is the artefact people tape to a wall; 159 says the same.
--
-- 3. NAME SPLIT IS THE UNIFORM RULE: first token = first_name, the rest =
--    last_name. That is what every prior seed does ('Angel'/'Gudino De Leon' in
--    031).
--    ⚠️ NO EXCEPTIONS WERE MADE, DELIBERATELY, and that is a change of posture
--    from 157 -- which carved out 'Amery A.'/'Schoepflin' for a middle initial.
--    Four rows here are genuinely ambiguous: 'Omar Josiah V Aviles',
--    'Bryan Neal II Harris', 'Ricardo JR Gonzalez' and
--    'Ka''Darious ONeal Lee Montgomery'. Is the surname 'Aviles' or 'V Aviles'?
--    Nobody here knows, and 157's own warning applies: "Do NOT replace this with
--    a middle-initial detector ... a guesser would be wrong the first time a
--    surname is an initial." PlayerTable renders "{first} {last}", so **every
--    one of these displays exactly as the coaches wrote it** regardless. This
--    only affects what the columns MEAN. If the staff confirm the real
--    surnames, it is a four-row UPDATE.
--
-- 4. POSITIONS AND SPELLINGS ARE VERBATIM. 'RB/K', 'OL/DL' and 'DL' as written.
--    No position cell has whitespace around its slash, so 158's 'DL/ LB' fix has
--    no analogue here -- checked, not assumed. 'Patrick Hernadez' is spelled
--    that way in the source and is left alone; 031 set the precedent by
--    preserving 'WIlliams'. Only a trailing space on 'Rashawn Mcdowell ' was
--    trimmed, which is whitespace, not spelling.
--
-- 5. ⚠️ GRADE IS NULL ON ALL 32, AND THIS IS THE FIRST ROSTER WHERE THAT IS
--    TRUE. The other 186 player rows across four rosters all have one. **The
--    source PDF simply has no class column** -- it is NUMBER / NAME / POSITION
--    and nothing else. Inventing grades from last season's roster would be
--    guessing about children, so the column stays empty and honest.
--    Consequence, so nobody reports it as a bug: on DESKTOP /roster/jv shows a
--    Grade column of em-dashes, because `dash()` renders "—" for null. On MOBILE
--    it disappears cleanly, because `mobileSep` drops empty parts. Height and
--    weight are already null for all 45 varsity players, so two dashed columns
--    are the existing look; this makes a third. One UPDATE if Coach sends them.
--
-- 6. THE PRINT VIEW USES THE COACHES' OWN PDF, NOT A GENERATED ONE. Varsity
--    needed `make-varsity-roster-pdf.py` because its source was a spreadsheet.
--    Here the source IS a finished PDF, so it was uploaded as-is to
--    documents/rosters/jv-2026.pdf (43,195 bytes, verified sha256-identical
--    after the round trip and fetching 200 as application/pdf). Nothing was
--    re-typeset, so the printed roster cannot disagree with the coaches'.

begin;

insert into players (roster_id, jersey_number, first_name, last_name, position, sort_order, active)
select r.id, v.jersey, v.first, v.last, v.pos, v.ord, true
from rosters r
cross join (values
  ('0', 'Antonio', 'Showels', 'RB', 1),
  ('4', 'Jake', 'Thomas', 'WR', 2),
  ('5', 'Michael', 'Jevin Menchaca', 'DB', 3),
  ('6', 'Alonzo', 'Warren Mata', 'WR', 4),
  ('7', 'Krishman', 'Hoff', 'WR', 5),
  ('8', 'Remiel', 'Avant Soto', 'RB/K', 6),
  ('9', 'Logan', 'Royce Moeller', 'QB', 7),
  ('10', 'Ka''Darious', 'ONeal Lee Montgomery', 'DB', 8),
  ('11', 'Case', 'Keough', 'DB', 9),
  ('12', 'Lamonte', 'Brown', 'RB', 10),
  ('13', 'Eli', 'Ricardo Thrift', 'WR', 11),
  ('14', 'Rashawn', 'Mcdowell', 'WR', 12),
  ('17', 'Zane', 'Bryant Valenzuela', 'DB', 13),
  ('18', 'Ricardo', 'JR Gonzalez', 'DB', 14),
  ('20', 'Oliver', 'Douglas Weisbrod', 'LB', 15),
  ('22', 'Byron', 'Deleon', 'WR', 16),
  ('23', 'Omar', 'Josiah V Aviles', 'LB', 17),
  ('24', 'Bryan', 'Neal II Harris', 'LB', 18),
  ('26', 'Zji''Sean', 'Tondrai Thomas', 'DB', 19),
  ('33', 'Isaac', 'Thomas Chandy', 'DB', 20),
  ('51', 'Jayden', 'Mark Fabien', 'OL/DL', 21),
  ('52', 'Caleb', 'Woodward', 'OL', 22),
  ('53', 'Patrick', 'Hernadez', 'OL', 23),
  ('56', 'Angel', 'Cruz Meza', 'DL', 24),
  ('64', 'Jaxon', 'Reed Pelosi', 'OL/DL', 25),
  ('66', 'Aiden', 'Robert Ross', 'OL', 26),
  ('67', 'Caleb', 'Lynn Cox', 'OL', 27),
  ('68', 'Mark', 'Gibson Llamas', 'LB', 28),
  ('75', 'Isaiah', 'Andrew Arias Faulkner', 'OL', 29),
  ('77', 'Jadien', 'Harris', 'OL', 30),
  ('84', 'Alexander', 'James Pugliese', 'WR', 31),
  ('88', 'Josiah', 'Harris', 'WR', 32)
) as v(jersey, first, last, pos, ord)
where r.year = '2026-27' and r.team_level = 'jv' and r.team_designation is null
  and not exists (select 1 from players p where p.roster_id = r.id);

update rosters
set pdf_storage_path = 'documents/rosters/jv-2026.pdf',
    source_note = 'JV roster provided by the McNeil coaching staff, received 2026-08-26'
where year = '2026-27' and team_level = 'jv' and team_designation is null;

do $$
declare n int; rid uuid;
begin
  select id into rid from rosters
   where year = '2026-27' and team_level = 'jv' and team_designation is null;
  if rid is null then raise exception 'no 2026-27 JV roster row to seed'; end if;

  select count(*) into n from players where roster_id = rid;
  if n <> 32 then raise exception 'expected 32 JV players, found %', n; end if;

  -- sort_order must be a dense 1..32 and must agree with jersey ascending.
  if (select count(distinct sort_order) from players where roster_id = rid) <> 32
     or (select min(sort_order) from players where roster_id = rid) <> 1
     or (select max(sort_order) from players where roster_id = rid) <> 32 then
    raise exception 'JV sort_order is not a dense 1..32 sequence';
  end if;
  select count(*) into n from (
    select sort_order,
           row_number() over (order by (jersey_number)::int) as by_jersey
    from players where roster_id = rid
  ) t where t.sort_order <> t.by_jersey;
  if n <> 0 then
    raise exception '% JV rows are not in jersey order (159 regression)', n;
  end if;

  -- Every jersey is a plain integer here, unlike varsity's dual numbers. If a
  -- future JV roster has '64/65' this cast fails loudly rather than mis-sorting.
  select count(*) into n from players
   where roster_id = rid and jersey_number !~ '^[0-9]+$';
  if n <> 0 then raise exception '% JV jersey numbers are not plain integers', n; end if;

  -- 158's fix must not have an analogue that slipped through.
  select count(*) into n from players
   where roster_id = rid and (position ~ '\s/' or position ~ '/\s');
  if n <> 0 then raise exception '% JV positions have whitespace around a slash', n; end if;

  -- No leading/trailing whitespace anywhere.
  select count(*) into n from players
   where roster_id = rid and (first_name <> btrim(first_name)
                          or last_name <> btrim(last_name)
                          or position  <> btrim(position));
  if n <> 0 then raise exception '% JV rows have untrimmed whitespace', n; end if;

  -- Print View wiring.
  select count(*) into n from rosters
   where id = rid and pdf_storage_path = 'documents/rosters/jv-2026.pdf';
  if n <> 1 then raise exception 'JV pdf_storage_path not set'; end if;

  -- The other three rosters are untouched.
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level <> 'jv';
  if n <> 45 then raise exception 'varsity player count changed: %', n; end if;
end $$;

commit;

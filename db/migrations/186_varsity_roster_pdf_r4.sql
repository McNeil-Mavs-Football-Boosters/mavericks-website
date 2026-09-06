-- 186_varsity_roster_pdf_r4.sql
--
-- Repoints /roster/varsity Print View at varsity-2026-r4.pdf, the regenerated
-- print roster carrying #67 Aiden Ross (OL, junior). Pairs with 183 + 184.
--
--   documents/rosters/varsity-2026-r3.pdf -> documents/rosters/varsity-2026-r4.pdf
--
-- ── THIS IS THE HALF OF A ROSTER CHANGE THAT KEEPS GETTING FORGOTTEN ──
-- The PDF is generated from the coaching staff's workbook
-- (`roster_pdf/source/Varsity McNeil Roster 2026.xlsx`, gitignored, only on
-- Jeremy's disk) by `scripts/make-varsity-roster-pdf.py`. Editing `players`
-- alone leaves the wall poster wrong. 171 hit this (Askins stayed 9/10 on the
-- printed roster after the DB was fixed), and 176 hit the schedule-PDF version
-- of it, where the site said Oct 9 and the downloadable PDF said Sep 4 for
-- twelve days. 178 established the fix: DO BOTH IN THE SAME SITTING.
--
-- 🚫 NEW FILENAME, NOT AN OVERWRITE. Every Supabase Storage object serves
-- `cache-control: no-cache` (a platform override), so Next's optimiser falls
-- back to `minimumCacheTTL` = 31 days and a replaced object can serve the OLD
-- bytes for a month with no way to invalidate. 158's rule; 169 and the roster
-- PDFs have all followed it. r3 stays in the bucket, unreferenced, so the
-- rollback has something to point back at.
--
-- ⚠️ The upload needs the key in the `apikey` HEADER as well as `Authorization`.
-- Supabase Storage now uses the new-style `sb_secret_…` keys, and a plain
-- Bearer-only upload fails with {"statusCode":"403","message":"Invalid Compact
-- JWS"} -- which reads like a permissions problem and is not (2026-08-29).
--
-- ── WHAT CHANGED IN THE WORKBOOK, AND WHAT DELIBERATELY DID NOT ──
-- One row inserted into the RIGHT block at sheet row 19, between #66 Frazier and
-- #71 Omagbon; E19:H24 shifted down one. Columns A-D were not touched.
--
-- ⚠️ THE TWO-BLOCK LAYOUT IS PRESERVED AND THE BLOCKS ARE NOW 23/23. 171 left
-- them 23/22 and said so; 46 players simply balances. 159 and 166 both say the
-- printed two-block order must NOT be reflowed into one column -- it is what
-- gets taped to a wall -- and equally the web page must not adopt the print
-- order. They stay different on purpose.
--
-- Jersey stored as the integer 67, matching every other plain number in the
-- sheet; only the four dual numbers are strings ('5/2', '84/80'). `cell_text`
-- renders either identically, so this is for whoever opens the workbook next.
--
-- Verified before this migration was written: the regenerated PDF is one page,
-- reads "46 players: 23 left block, 23 right block", extracts "67 Aiden Ross OL
-- 11" between Frazier and Omagbon, keeps the staff credit block, and the object
-- served from Storage is byte-identical (sha256) to the local file.
--
-- DB-ONLY, NO DEPLOY. The Print View link reads this column at request time.
--
-- ⚠️ Only the VARSITY roster row is repointed. The JV and freshman rows keep
-- their own `pdf_storage_path`, and the shared `schedule_pdf_storage_path`
-- (2026-27-r3.pdf) is a different artefact entirely -- it is the season schedule,
-- not a roster, and nothing here touches it.
--
-- Rollback: 186_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r3.pdf';
  if n <> 1 then raise exception 'varsity roster is not on r3 (found %)', n; end if;

  -- The PDF being pointed at claims 46 players. The DB had better agree, or the
  -- wall poster and the page disagree the moment this commits.
  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null;
  if n <> 46 then raise exception 'varsity roster has % players, but r4 was built for 46', n; end if;

  select count(*) into n from players p
    join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null
     and p.jersey_number = '67' and p.first_name = 'Aiden' and p.last_name = 'Ross'
     and p.position = 'OL' and p.grade = 'Jr.';
  if n <> 1 then raise exception 'Aiden Ross is not in the DB as r4 prints him'; end if;
end $$;

update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf', updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

do $$
declare n int;
begin
  select count(*) into n from rosters
   where year = '2026-27' and team_level = 'varsity' and team_designation is null
     and pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf';
  if n <> 1 then raise exception 'repoint did not take'; end if;

  -- Nothing else moved to r4, and no other roster row lost its own PDF.
  select count(*) into n from rosters
   where year = '2026-27' and pdf_storage_path = 'documents/rosters/varsity-2026-r4.pdf';
  if n <> 1 then raise exception '% rows point at r4', n; end if;

  select count(*) into n from rosters
   where year = '2026-27' and coalesce(schedule_pdf_storage_path, '') <> 'documents/schedules/2026-27-r3.pdf';
  if n <> 0 then raise exception 'the shared schedule PDF pointer was disturbed on % row(s)', n; end if;
end $$;

commit;

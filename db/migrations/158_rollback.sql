-- 158_rollback.sql
--
-- Restore the three parenthesised jersey numbers, the 'DL/ LB' spacing, and the
-- original PDF path, putting the roster back exactly as 157 left it.
--
-- ⚠️ Written as explicit per-player UPDATEs, not as a regex. There is no rule
-- that can re-derive WHICH of the five dual numbers were parenthesised in the
-- source -- that information only exists in the spreadsheet and in this file.
-- A generic "re-add parens" would wrap '64/65' and '84/80' too, which were
-- never parenthesised.
--
-- varsity-2026.pdf is still in the bucket (158 uploaded a new object rather
-- than overwriting), so this path resolves. It has the parens and the stray
-- space, matching the restored rows.

begin;

update players p
   set jersey_number = '(' || p.jersey_number || ')'
  from rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and r.team_designation is null
   and p.jersey_number in ('5/2', '8/18', '9/10');

update players p
   set position = 'DL/ LB'
  from rosters r
 where p.roster_id = r.id
   and r.year = '2026-27' and r.team_level = 'varsity'
   and r.team_designation is null
   and p.last_name = 'Galaza'
   and p.position = 'DL/LB';

update rosters
   set pdf_storage_path = 'documents/rosters/varsity-2026.pdf'
 where year = '2026-27'
   and team_level = 'varsity'
   and team_designation is null;

commit;

-- 148_rollback.sql -- restores the two-freshman-team configuration.
--
-- Safe to run: migration 148 never deleted anything, so this is a pure
-- re-enable. The 12 freshman Blue game rows were left untouched and become
-- visible again the moment the flag flips back.

begin;

update site_settings set freshman_has_blue = true;

update rosters
   set active = true
 where year = '2026-27'
   and team_level = 'freshman'
   and team_designation = 'Blue';

commit;

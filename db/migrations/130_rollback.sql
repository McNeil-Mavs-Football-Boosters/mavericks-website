-- 130_rollback.sql — puts the four Aug 20 Eastview rows back to the
-- time-TBD state migration 078 seeded (nominal 6:00 PM, result_status 'tbd',
-- which renders as "TBD" in the time cell).

begin;

update games
   set game_date = '2026-08-20 18:00:00-05'::timestamptz,
       result_status = 'tbd'
 where year = '2026-27' and opponent = 'Eastview High School';

commit;

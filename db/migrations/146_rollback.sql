-- 146_rollback.sql — label back to 'Bowie HS'. Note this restores the state
-- where the page text and its map link disagree; if you run this, run
-- 145_rollback.sql too and re-patch the PDF.

begin;

update games
   set location = 'Bowie HS'
 where year = '2026-27' and location = 'Burger Stadium'
   and opponent = 'Austin Bowie High School' and team_level = 'freshman';

commit;

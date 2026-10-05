-- 224_rollback.sql
--
-- Reopens the varsity Oct 2 Cedar Ridge row (final 29-70 -> scheduled, scores
-- cleared). Note this also puts the two Cedar Ridge broadcast links back up.

begin;

update games
   set result_status = 'scheduled', our_score = null, their_score = null, updated_at = now()
 where year = '2026-27' and team_level = 'varsity'
   and game_date = timestamptz '2026-10-02 19:00 America/Chicago'
   and opponent = 'Cedar Ridge High School'
   and result_status = 'final' and our_score = 29 and their_score = 70;

commit;

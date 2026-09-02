-- 180_rollback.sql — restores the Aug 28 replay and removes the Sep 4 rows.
-- ⚠️ Reactivating the Aug 28 YouTube link republishes a replay that VYPE took
-- down at the request of Bowie's coach. Do not run this half.

begin;

delete from game_broadcasts b
 using games g
 where g.id = b.game_id
   and g.game_date = timestamptz '2026-09-04 19:00 America/Chicago';

update game_broadcasts b
   set active = true, updated_at = now()
  from games g
 where g.id = b.game_id
   and g.game_date = timestamptz '2026-08-28 19:30 America/Chicago';

commit;

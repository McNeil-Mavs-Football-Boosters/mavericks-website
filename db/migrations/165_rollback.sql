-- 165_rollback.sql — restores games.watch_url, then drops game_broadcasts.
--
-- ⚠️ ORDER MATTERS AND A BARE `drop table` WOULD LOSE DATA. 165 carried the one
-- legacy `watch_url` (the 2025-26 Hutto row, migration 052) into
-- game_broadcasts and then blanked the column. Dropping the table first would
-- destroy the only remaining copy. So this puts it back FIRST, from the table,
-- and only then drops it.
--
-- ⚠️ THE CODE MUST GO BACK TOO. 165 shipped with a render change — the schedule
-- reads broadcasts in `LinksCell` and the "Watch →" branch was removed from
-- `ResultCell`. Running this against the deployed site leaves the query
-- selecting a table that no longer exists. Revert the commit, then run this.
-- Dropping the table alone is not a rollback.
--
-- The week's VYPE links ARE lost, deliberately. They are cheap to re-add (they
-- are in Merle's 2026-08-24 email and in 165 itself), unlike a logo, so there
-- is no reason to preserve them the way 164_rollback preserves storage objects.
-- Only the pre-165 legacy value is restored, because that one has no other home.

begin;

update games g
set watch_url = b.url
from game_broadcasts b
where b.game_id = g.id
  and b.url = 'https://www.youtube.com/@iHSFan';

do $$
declare n int;
begin
  select count(*) into n from games where watch_url is not null;
  if n <> 1 then
    raise exception 'expected to restore exactly 1 legacy watch_url, restored %', n;
  end if;
end $$;

drop table if exists game_broadcasts;

do $$
begin
  if exists (select 1 from information_schema.tables
              where table_schema = 'public' and table_name = 'game_broadcasts') then
    raise exception 'game_broadcasts survived rollback';
  end if;

  -- 165 emptied this column but never dropped it.
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'games'
                    and column_name = 'watch_url') then
    raise exception 'games.watch_url is missing — 165 was not supposed to drop it';
  end if;
end $$;

commit;

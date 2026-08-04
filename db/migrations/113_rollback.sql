-- 113_rollback.sql
--
-- Reactivate the Program Ad add-on. Use this next season rather than writing a
-- fresh INSERT.
--
-- ⚠️ Before running: the row's description still reads "Commit by July 31 to
-- make this season's program." That date is season-specific and will be wrong.
-- Update it in the same transaction, or the card goes back up advertising a
-- stale deadline, which is the exact bug 113 was written to fix.

begin;

update sponsorship_tiers
set active = true
where year = '2026-27'
  and is_addon
  and name = 'Program Ad';

commit;

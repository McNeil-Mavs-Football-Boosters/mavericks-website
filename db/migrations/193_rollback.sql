-- 193_rollback.sql
--
-- Restores the shorter 192 descriptions: the mention line back mid-sentence and
-- no shirt line.
-- ⚠️ Rolling this back removes an operational promise families may already have
-- read. If merch will not be at an event, prefer editing the shirt sentence out
-- forward rather than reverting the mention-line promotion with it.

begin;

update events
   set description = 'Join the Mavs for a Spirit Night at The League Kitchen & Tavern (Avery and Parmer) on Monday, September 14, 6:00-8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-the-league-2026-09-14';

update events
   set description = 'Join the Mavs for a Spirit Night at Mighty Fine Burgers at Arbor Walk on Wednesday, September 30, 6:00-8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-mighty-fine-2026-09-30';

commit;

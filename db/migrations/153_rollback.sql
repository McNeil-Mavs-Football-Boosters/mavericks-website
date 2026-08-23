-- 153_rollback.sql — there is no automated rollback for this migration.
--
-- It replaced whole bodies rather than editing lines, and the prior contents
-- were Week 3 (Aug 17-23), a week that has already PASSED. Restoring them
-- would put a stale schedule back in front of families, which is worse than
-- the problem any rollback would be solving.
--
-- If Week 4 needs to be corrected, write a NEW migration with the corrected
-- text. If Week 3's exact text is ever needed for the record, recover it from
-- migrations 129 / 133 / 150 / 152 and git history rather than from here.
--
-- Intentionally a no-op.

select 'no-op: see 153_rollback.sql header' as note;

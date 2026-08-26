-- 163_rollback.sql -- closes Blue again, restoring the post-160 state.
begin;
update sponsorship_tiers set available = false
where year = '2026-27' and name = 'Blue';
commit;

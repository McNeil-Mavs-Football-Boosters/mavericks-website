-- 160_rollback.sql -- reopens all levels and drops the column.
--
-- ⚠️ To simply RE-OPEN the levels next summer, do NOT run this. Run:
--     update sponsorship_tiers set available = true where year = '<year>';
-- Dropping the column throws away the ability to close a level again.

begin;

alter table sponsorship_tiers drop column if exists available;

commit;

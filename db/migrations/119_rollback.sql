-- 119_rollback.sql
-- Rudy's stops appearing under Community Partners; stays a Scoreboard sponsor.
-- ⚠️ Dropping the column clears the flag for EVERY business, not just Rudy's.
-- To remove one, prefer: update sponsors set provides_in_kind=false where id='...';

begin;
alter table sponsors drop column if exists provides_in_kind;
commit;

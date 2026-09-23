-- 212_rollback.sql
begin;
delete from resource_links where url like '%1zFsehMoFYR4SS6Ow17CML9HZuds34bEgR8q0Z4iFm5s%';
commit;

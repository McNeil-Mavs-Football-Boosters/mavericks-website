-- 107_rollback.sql
-- Returns both sponsors to having no website link (their 106 state).

begin;

update sponsors
set website_url = null
where year = '2026-27'
  and name in ('Capstone Acquisitions', 'Mama Betty''s Tex-Mex');

commit;

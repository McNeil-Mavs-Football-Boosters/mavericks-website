-- 147_rollback.sql — reactivates the three stadium links. ⚠️ Fix them first:
-- Dragon Stadium's URL is the 300 N Lake Creek Dr address that migration 135
-- rejected, and House Park is not a 2026-27 venue. Reactivating as-is republishes
-- a wrong pin. The page-side SECTION_ORDER entry must be restored too, or these
-- rows will render under "Other".

begin;

update resource_links set active = true where section = 'stadiums';

commit;

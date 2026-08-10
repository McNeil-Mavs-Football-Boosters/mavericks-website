-- 121_santiagos_partner.sql
--
-- Santiago's Tex-Mex & Cantina (Cat Hollow) joins Community Partners. In-kind,
-- so no tier. Jeremy 2026-08-09. URL verified 200: title "Tex-Mex Cantina &
-- Margaritas in Round Rock TX | Santiago's".
--
-- Logo was pulled from THEIR OWN SITE, not the screenshot supplied:
-- static.spotapps.co/.../custom/logo.png carries real transparency, whereas the
-- screenshot had a solid black backing that would have rendered as a black tile.
-- (It is also what Kendra's own asset spec asks sponsors for: not a screenshot.)
-- ⚠️ Only 142x171, so it is soft on retina — a larger original would be better.
--
-- sort_order 0 like every other partner: the partner list orders by NAME, so
-- nothing needs renumbering when one is added.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Santiago''s Tex-Mex & Cantina', 'santiagos.png',
       'https://cathollow.santiagostexmexandcantina.com/',
       null, '2026-27', 'community_partner', true, 0, false
where not exists (
  select 1 from sponsors where name = 'Santiago''s Tex-Mex & Cantina' and year = '2026-27'
);

commit;

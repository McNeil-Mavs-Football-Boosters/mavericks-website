-- 094_readd_rudys_sponsor.sql
--
-- Re-adds Rudy's BBQ as an MVP-tier sponsor. Migration 060 removed it on the
-- belief it was a placeholder; Jeremy confirmed (2026-07-26) Rudy's is a real
-- sponsor. Restored exactly as migration 041 seeded it (MVP tier, sort_order 1,
-- year 2025-26). The logo object (sponsor-logos/rudys-bbq.png) is still present.
-- MVP is otherwise empty, so Rudy's renders alone at the top/largest size, which
-- also demonstrates the tier-size hierarchy to prospects. Idempotent.

BEGIN;

INSERT INTO sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active)
SELECT 'Rudy''s BBQ', 'rudys-bbq.png', 'https://rudysbbq.com',
       'a1e5e262-ad4a-46c7-8e5b-7752bb653b23', '2025-26', false, 1, true
WHERE NOT EXISTS (
  SELECT 1 FROM sponsors WHERE name = 'Rudy''s BBQ' AND year = '2025-26'
);

COMMIT;

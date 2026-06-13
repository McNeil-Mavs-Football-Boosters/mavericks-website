-- 060_rollback.sql
-- Reverses 060 by re-inserting the Rudy's BBQ sponsor row exactly as
-- migration 041 seeded it (MVP tier, sort_order 1, year 2025-26).

BEGIN;

INSERT INTO sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active)
VALUES (
  'Rudy''s BBQ',
  'rudys-bbq.png',
  'https://rudysbbq.com',
  'a1e5e262-ad4a-46c7-8e5b-7752bb653b23',
  '2025-26',
  false,
  1,
  true
);

COMMIT;

-- Migration 007: Views (public_members)

-- View exposes only display-safe columns: id, year, tier name + sort, parent names.
-- Does NOT expose: emails, phones, t-shirt sizes, donation amounts, employer match,
-- SportsYou opt-in status, paid status, payment_id.
--
-- security_invoker = false means the view runs as its owner (the postgres superuser
-- in Supabase), bypassing the underlying memberships table RLS. That's the entire
-- point of using a view here — column-level safety the RLS row-filter can't provide.

CREATE VIEW public_members
WITH (security_invoker = false)
AS
  SELECT
    m.id,
    m.year,
    mt.name AS tier_name,
    mt.sort_order AS tier_sort_order,
    m.parent_1_name,
    m.parent_2_name
  FROM memberships m
  JOIN membership_tiers mt ON mt.id = m.tier_id
  WHERE m.list_publicly = true
    AND m.paid = true
    AND m.active = true
    AND mt.active = true;

GRANT SELECT ON public_members TO anon, authenticated;

-- The /members Next.js page queries this view filtered by year:
--   SELECT * FROM public_members WHERE year = '2026-27'
--   ORDER BY tier_sort_order DESC, parent_1_name;

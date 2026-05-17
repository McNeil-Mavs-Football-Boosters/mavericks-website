-- Migration 018b: Seed Michael Hale (Defensive Coordinator) on coaches

INSERT INTO coaches (year, name, role, role_category, email, sort_order, active) VALUES
  ('2026-27', 'Michael Hale', 'Defensive Coordinator', 'coordinator', 'Michael_Hale@roundrockisd.org', 5, true);

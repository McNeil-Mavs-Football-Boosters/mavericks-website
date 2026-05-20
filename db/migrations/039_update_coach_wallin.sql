-- Migration 039: Update Coach Wallin's name + role.
-- Spec: docs/specs/commit_print_view_pdfs_spec.md Part 2 (2026-05-19).
--
-- Pre-migration state (confirmed via SELECT before applying):
--   name           = 'Coach Wallin'
--   role           = 'Position Coach'
--   role_category  = 'position_coach'
--
-- Spec wording note: spec says "position" but the column is `role`. Updating `role`.
-- Head-coach check: role_category is 'position_coach', not 'head' — no slot clearing
-- needed. Wallin stays in the Position Coaches section.

UPDATE coaches
SET name = 'Douglas Wallin',
    role = 'Defensive Line Coach'
WHERE id = 'a4e36da9-6371-4400-a9c7-dbed6ddce0fa';

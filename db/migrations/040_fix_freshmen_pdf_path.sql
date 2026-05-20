-- Migration 040: Fix freshman roster PDF path to use 'freshmen' (plural).
-- Migration 038 seeded 'freshman-2025.pdf' (singular, matching the team_level enum),
-- but the uploaded file in Storage is 'freshmen-2025.pdf' (plural, matching the
-- source PDF filename). Per Jeremy's preference, the storage filename stays plural.

UPDATE rosters
SET pdf_storage_path = 'documents/rosters/freshmen-2025.pdf'
WHERE year = '2025-26' AND team_level = 'freshman';

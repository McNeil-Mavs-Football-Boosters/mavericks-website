-- Rollback for migration 040: restore the singular 'freshman' path from 038.

UPDATE rosters
SET pdf_storage_path = 'documents/rosters/freshman-2025.pdf'
WHERE year = '2025-26' AND team_level = 'freshman';

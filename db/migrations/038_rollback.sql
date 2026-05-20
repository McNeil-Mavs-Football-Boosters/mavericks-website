-- Rollback for migration 038.
-- Drops the two new columns and clears the documents-bucket size/MIME constraints.
-- The bucket itself stays — it predates 038 (see migration 009). Uploaded files
-- in documents/* are preserved by the rollback; delete them manually via Studio
-- if you want a clean slate.

ALTER TABLE rosters DROP COLUMN IF EXISTS pdf_storage_path;
ALTER TABLE rosters DROP COLUMN IF EXISTS schedule_pdf_storage_path;

UPDATE storage.buckets
SET file_size_limit = NULL,
    allowed_mime_types = NULL
WHERE id = 'documents';

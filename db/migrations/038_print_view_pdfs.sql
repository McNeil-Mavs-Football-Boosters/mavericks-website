-- Migration 038: Print View PDF wiring — bucket config + schema columns + 2025-26 seed.
-- Spec: docs/specs/commit_print_view_pdfs_spec.md (2026-05-19).
--
-- Conflicts with spec, resolved per "default to your reading" guidance:
--   * Spec assumed `team_levels` table exists; it does NOT. `team_level` is an ENUM
--     ('varsity','jv','freshman') and per-team-per-year metadata lives on `rosters`
--     (one row per (year, team_level, team_designation)).
--   * Spec assumed `freshman_green` / `freshman_blue` enum values; freshman color
--     split is actually in `rosters.team_designation` (text: 'Green' or 'Blue').
--   * `documents` bucket already exists (created in or before migration 009, which
--     also pre-baked the RLS read/write policies for it). Bucket needs UPDATE for
--     size + MIME constraints, not INSERT.
--
-- Resolution: add BOTH pdf_storage_path AND schedule_pdf_storage_path to `rosters`.
-- That table is already the per-team-per-year anchor at the cardinality the spec
-- wants for per-team schedule PDFs (Option B — "per-team schedule PDFs from day
-- one"). Schedule pages will look up the matching rosters row for their PDF path.

-- -----------------------------------------------------------------------------
-- documents bucket config (bucket already exists; tighten constraints)
-- -----------------------------------------------------------------------------
UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['application/pdf']
WHERE id = 'documents';

-- Public read policy on storage.objects for 'documents' was provisioned by
-- migration 009 ("Anyone reads public buckets"). No new policy needed here.

-- -----------------------------------------------------------------------------
-- Schema: PDF path columns on rosters
-- -----------------------------------------------------------------------------
ALTER TABLE rosters ADD COLUMN pdf_storage_path text;
ALTER TABLE rosters ADD COLUMN schedule_pdf_storage_path text;

-- -----------------------------------------------------------------------------
-- Seed: 2025-26 PDF paths
-- -----------------------------------------------------------------------------

-- Varsity + JV — one row each, team_designation IS NULL.
UPDATE rosters SET pdf_storage_path = 'documents/rosters/varsity-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'varsity';

UPDATE rosters SET pdf_storage_path = 'documents/rosters/jv-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'jv';

-- Freshman — both Green and Blue rows get the same path for 2025-26 (per spec).
-- Filter on team_level alone catches both team_designation rows.
UPDATE rosters SET pdf_storage_path = 'documents/rosters/freshman-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'freshman';

-- Schedule PDF — all four 2025-26 rosters get the same path. Diverge later by
-- UPDATEing individual (team_level, team_designation) rows.
UPDATE rosters SET schedule_pdf_storage_path = 'documents/schedules/2025-26.pdf'
  WHERE year = '2025-26';

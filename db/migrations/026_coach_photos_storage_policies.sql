-- Migration 026: Storage policies for the coach-photos bucket.
--
-- Bucket is created via Supabase Studio (per schema_v2.md §"What does NOT change"):
--   coach-photos: public, max 5MB, image/png + image/jpeg + image/webp
--
-- Mirrors the 4-policy pattern from 009_storage_policies.sql, scoped to bucket_id
-- = 'coach-photos' so it can diverge from the shared image buckets later if needed
-- (e.g., RRISD consent rules for coach photos vs. parent-volunteer board photos).

CREATE POLICY "Anyone reads coach photos" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'coach-photos');

CREATE POLICY "Content admins upload coach photos" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins update coach photos" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins delete coach photos" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

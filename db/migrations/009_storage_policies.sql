-- Migration 009: Storage policies (Supabase Storage)

-- Buckets are created via Supabase Studio (already done):
--   news-images, event-images, sponsor-logos, board-photos, site-images, documents
-- All buckets are public so Next.js pages can load referenced URLs without signed URLs.
--
-- These policies govern who can upload/update/delete files in those buckets via
-- storage.objects RLS. Anyone (anon + authenticated) can read; only content_admins
-- can write.

-- All buckets above: anyone can read, only authenticated content_admins can write/delete

CREATE POLICY "Anyone reads public buckets" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents'));

CREATE POLICY "Content admins upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

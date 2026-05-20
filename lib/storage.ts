// Bucket-relative path inside `site-images` (e.g. "hero/hero-01.jpg" -> full URL).
// Used by hero carousel content. Bucket is hardcoded because hero rows only ever
// live in site-images.
export function publicStorageUrl(storagePath: string): string {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL — cannot build public storage URL",
    );
  }
  const base = url.replace(/\/$/, "");
  return `${base}/storage/v1/object/public/site-images/${storagePath}`;
}

// Bucket-PREFIXED absolute path (e.g. "documents/rosters/varsity-2025.pdf").
// Used wherever the stored path encodes which bucket the object lives in —
// currently the rosters PDF + schedule PDF fields, per the Print View spec.
export function publicObjectUrl(absolutePath: string): string {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL — cannot build public storage URL",
    );
  }
  const base = url.replace(/\/$/, "");
  return `${base}/storage/v1/object/public/${absolutePath}`;
}

// Bucket-relative path resolves to a public storage URL. Default bucket is
// `site-images` (hero carousel content); callers reading from other public
// buckets (e.g. `sponsor-logos`) pass the bucket name as a second arg.
export function publicStorageUrl(
  storagePath: string,
  bucket: string = "site-images",
): string {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL — cannot build public storage URL",
    );
  }
  const base = url.replace(/\/$/, "");
  return `${base}/storage/v1/object/public/${bucket}/${storagePath}`;
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

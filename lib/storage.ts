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

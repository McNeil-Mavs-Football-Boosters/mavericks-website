import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Page not found",
};

// Force dynamic rendering so unmatched routes (e.g. /schedule/games/varsity
// before the page is built) re-read site_settings on every request. ISR's
// revalidate=60 was getting bypassed for catch-all 404 fallback URLs because
// Vercel's edge cache keys them outside of the route's revalidation cycle.
export const dynamic = "force-dynamic";

export default function NotFound() {
  return (
    <div className="py-24 text-center">
      <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl mb-4">Page not found.</h1>
      <p className="text-muted-foreground mb-8">
        We couldn&apos;t find the page you were looking for. Try one of these instead:
      </p>
      <ul className="flex flex-wrap justify-center gap-x-6 gap-y-2 text-mavs-navy font-medium">
        <li><Link href="/" className="hover:underline">Home</Link></li>
        <li><Link href="/about" className="hover:underline">About</Link></li>
        <li><Link href="/contact" className="hover:underline">Contact</Link></li>
      </ul>
    </div>
  );
}

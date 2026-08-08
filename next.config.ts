import type { NextConfig } from "next";
import createMDX from "@next/mdx";

const nextConfig: NextConfig = {
  pageExtensions: ["ts", "tsx", "md", "mdx"],
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "*.supabase.co",
        pathname: "/storage/v1/object/public/**",
      },
    ],
    // Vercel warned at 75% of the free tier's 100,000 Image Optimization cache
    // writes on 2026-08-07. Only SEVEN source images are even metered here — the
    // six hero backgrounds plus the local brand logo — because coach photos and
    // sponsor logos render through a plain <img>. So that number was churn, not
    // traffic.
    //
    // Cause: every Supabase Storage object serves `cache-control: no-cache`.
    // Next computes an optimized image's lifetime as
    //     max(minimumCacheTTL, upstream max-age)
    // so with no-cache upstream it fell back to the Next 16 default of 4 hours,
    // and every variant was re-optimized 6x a day forever. Vercel's image cache
    // is also regional, so each edge region re-wrote its own copy on that clock.
    //
    // 31 days. The hero images are immutable in practice — migration 037 seeded
    // them at fixed paths and a change means a new row/path.
    // ⚠️ TRADEOFF: replacing an image AT THE SAME storage path will serve stale
    // for up to 31 days. To force a refresh, upload under a new filename and
    // update the row (preferred, matches how sponsor logos are handled), or add
    // a ?v=N to the stored path.
    minimumCacheTTL: 2678400,
    // Default is 8 widths up to 3840, and every width is a separately cached and
    // separately BILLED variant. This site's only full-bleed image is a hero
    // photo sitting behind a dark scrim, where a 4K variant buys nothing
    // perceptible. Four widths halves the variant count.
    deviceSizes: [640, 828, 1080, 1920],
  },
};

const withMDX = createMDX({});

export default withMDX(nextConfig);

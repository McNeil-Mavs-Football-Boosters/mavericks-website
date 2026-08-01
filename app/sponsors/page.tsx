import Link from "next/link";

import { getSiteSettingsCore } from "@/lib/site-settings";
import { publicStorageUrl } from "@/lib/storage";
import { createServerClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Our Sponsors | McNeil Mavericks Football",
  description:
    "McNeil Mavericks Football thanks the local businesses sponsoring our season.",
};

interface Sponsor {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
  tier_id: string | null;
  sort_order: number;
  year: string;
}

interface SponsorshipTier {
  id: string;
  name: string;
  sort_order: number;
  year: string;
  price_cents: number;
}

// Widths are min(Npx, 100%) rather than a bare Npx: the MVP box is 440px,
// wider than a 390px phone viewport, and a bare max-width let Rudy's logo push
// the whole page into horizontal scroll. The 100% term clamps to the container
// on small screens while keeping the intended per-tier hierarchy on desktop.
const TIER_SIZE_CLASSES: Record<string, string> = {
  MVP: "max-h-60 max-w-[min(440px,100%)]",
  Diamond: "max-h-48 max-w-[min(360px,100%)]",
  Platinum: "max-h-40 max-w-[min(320px,100%)]",
  Gold: "max-h-32 max-w-[min(280px,100%)]",
  Blue: "max-h-24 max-w-[min(200px,100%)]",
};

function tierSizeClasses(tierName: string): string {
  return TIER_SIZE_CLASSES[tierName] ?? "max-h-32 max-w-[min(280px,100%)]";
}

function SponsorCard({
  sponsor,
  sizeClasses,
}: {
  sponsor: Sponsor;
  sizeClasses: string;
}) {
  if (!sponsor.logo_url) return null;
  const logoSrc = publicStorageUrl(sponsor.logo_url, "sponsor-logos");
  const img = (
    /* eslint-disable-next-line @next/next/no-img-element */
    <img
      src={logoSrc}
      alt={sponsor.name}
      className={`${sizeClasses} w-auto h-auto object-contain`}
    />
  );
  return (
    <div className="flex items-center justify-center">
      {sponsor.website_url ? (
        <a
          href={sponsor.website_url}
          target="_blank"
          rel="noopener noreferrer"
          className="hover:opacity-80 transition-opacity"
          aria-label={`Visit ${sponsor.name}`}
        >
          {img}
        </a>
      ) : (
        img
      )}
    </div>
  );
}

export default async function SponsorsPage() {
  const { current_year } = await getSiteSettingsCore();
  const supabase = createServerClient();

  const [tiersResult, sponsorsResult] = await Promise.all([
    supabase
      .from("sponsorship_tiers")
      .select("id, name, sort_order, year, price_cents")
      .eq("year", current_year)
      .eq("active", true)
      // Premier tier first: MVP -> Diamond -> Platinum -> Gold -> Blue -> Custom.
      // Ordered by price DESC, NOT by reversing sort_order -- sort_order runs
      // Blue=1 .. MVP=5, Custom=6, so descending sort_order would put Custom
      // (a $0 placeholder tier) at the top. This is the showcase page, where
      // the biggest supporters should read first; the /boosters/sponsor sign-up
      // ladder keeps its own low-to-high ordering.
      .order("price_cents", { ascending: false }),
    supabase
      .from("sponsors")
      .select("id, name, logo_url, website_url, tier_id, sort_order, year")
      .eq("year", current_year)
      .eq("active", true)
      .order("sort_order", { ascending: true }),
  ]);

  if (tiersResult.error) {
    console.error("[app/sponsors] tiers fetch failed", tiersResult.error);
  }
  if (sponsorsResult.error) {
    console.error("[app/sponsors] sponsors fetch failed", sponsorsResult.error);
  }

  const tiers: SponsorshipTier[] = (tiersResult.data ?? []) as SponsorshipTier[];
  const sponsors: Sponsor[] = (sponsorsResult.data ?? []) as Sponsor[];

  const sponsorsByTier = new Map<string, Sponsor[]>();
  const unaffiliatedSponsors: Sponsor[] = [];

  for (const s of sponsors) {
    if (s.tier_id == null) {
      unaffiliatedSponsors.push(s);
    } else {
      const bucket = sponsorsByTier.get(s.tier_id);
      if (bucket) {
        bucket.push(s);
      } else {
        sponsorsByTier.set(s.tier_id, [s]);
      }
    }
  }

  // Empty state: no sponsors at all for the current year.
  if (sponsors.length === 0) {
    return (
      <section className="container mx-auto px-4 py-16 md:py-24 text-center">
        <h1 className="text-4xl md:text-5xl font-black uppercase tracking-tight text-mavs-navy">
          Our Sponsors
        </h1>
        <div className="h-1 w-20 bg-mavs-green mx-auto mt-4"></div>
        <p className="text-lg text-gray-600 mt-6 max-w-xl mx-auto">
          We&apos;re building our {current_year} sponsor program. Be the first
          to put your business in front of every Mavs family this season.
        </p>
        <Link
          href="/boosters/sponsor"
          className="inline-block mt-8 bg-mavs-navy text-white px-8 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors"
        >
          Become Our First Sponsor →
        </Link>
      </section>
    );
  }

  return (
    <>
      {/* Page header */}
      <section className="bg-mavs-navy text-white">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-4">
            <div>
              <h1 className="text-4xl md:text-5xl font-black uppercase tracking-tight">
                Our Sponsors
              </h1>
              <div className="h-1 w-20 bg-mavs-green mt-3"></div>
              <p className="text-lg text-white/80 mt-3">
                {current_year} Season
              </p>
            </div>
            <Link
              href="/boosters/sponsor"
              className="bg-mavs-green text-white px-6 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors inline-block"
            >
              Become a Sponsor →
            </Link>
          </div>
        </div>
      </section>

      {/* Tier sections */}
      {tiers.map((tier) => {
        const tierSponsors = sponsorsByTier.get(tier.id);
        if (!tierSponsors || tierSponsors.length === 0) return null;
        const sizeClasses = tierSizeClasses(tier.name);
        return (
          <section
            key={tier.id}
            className="container mx-auto px-4 py-10 md:py-14 border-t-2 border-mavs-green/30"
          >
            <h2 className="text-2xl md:text-3xl font-bold uppercase tracking-tight text-mavs-navy mb-2">
              {tier.name} Sponsors
            </h2>
            <div className="h-0.5 w-12 bg-mavs-green mb-8"></div>
            <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
              {tierSponsors.map((sponsor) => (
                <SponsorCard
                  key={sponsor.id}
                  sponsor={sponsor}
                  sizeClasses={sizeClasses}
                />
              ))}
            </div>
          </section>
        );
      })}

      {/* Other Supporters (tier_id IS NULL) */}
      {unaffiliatedSponsors.length > 0 && (
        <section className="container mx-auto px-4 py-10 md:py-14 border-t-2 border-mavs-green/30">
          <h2 className="text-2xl md:text-3xl font-bold uppercase tracking-tight text-mavs-navy mb-2">
            Other Supporters
          </h2>
          <div className="h-0.5 w-12 bg-mavs-green mb-8"></div>
          <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
            {unaffiliatedSponsors.map((sponsor) => (
              <SponsorCard
                key={sponsor.id}
                sponsor={sponsor}
                sizeClasses="max-h-24 max-w-[min(200px,100%)]"
              />
            ))}
          </div>
        </section>
      )}

      {/* Footer CTA card */}
      <section className="container mx-auto px-4 py-12 md:py-16">
        <div className="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden">
          <div className="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight">
            Want to Join Them in 2026-27?
          </h2>
          <p className="text-lg text-white/90 mt-4 max-w-2xl mx-auto">
            Sponsorship levels for every budget, plus add-ons. Each one supports
            McNeil football and puts your business in front of Mavs families all
            season long.
          </p>
          <Link
            href="/boosters/sponsor"
            className="bg-mavs-green text-white px-8 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors inline-block mt-8"
          >
            See Sponsorship Options
          </Link>
        </div>
      </section>
    </>
  );
}

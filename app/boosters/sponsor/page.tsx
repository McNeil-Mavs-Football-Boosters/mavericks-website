import { Download } from "lucide-react";
import Link from "next/link";

import {
  SponsorStripLogo,
  type SponsorStripLogoSponsor,
} from "@/components/sponsors/SponsorStripLogo";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { publicObjectUrl } from "@/lib/storage";
import { createServerClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

// Full booster sponsorship letter (hosted in the documents bucket). The ?download
// param sets Content-Disposition: attachment so the link downloads rather than
// opening in a tab (the HTML `download` attr is ignored cross-origin).
const SPONSORSHIP_LETTER_URL =
  publicObjectUrl("documents/sponsorship/sponsorship-letter-2026-27.pdf") +
  "?download=McNeil-Sponsorship-Letter-2026-27.pdf";

export const metadata = {
  title: "Become a Sponsor | McNeil Mavericks Football",
  description:
    "Support McNeil Mavericks Football. Six sponsorship levels plus add-ons, real visibility, every level supports the program.",
};

interface SponsorshipTier {
  id: string;
  name: string;
  price_cents: number;
  description: string | null;
  perks: string[];
  sort_order: number;
  badge_label: string | null;
  year: string;
  is_addon: boolean;
  price_flexible: boolean;
  term_label: string | null;
}

type Sponsor = SponsorStripLogoSponsor & {
  tier_id: string | null;
  sort_order: number;
  year: string;
};

// Concrete examples of what sponsorship dollars fund. Editable per Jeremy 2026-06-23.
const SPONSORSHIP_FUNDS = [
  "Character Wins curriculum",
  "Riddell SpeedFlex helmets",
  "Weekly game streaming subscription",
  "Hudl subscription",
  "ANSRS subscription",
  "Meals and transportation for the students",
  "Offensive line knee braces",
  "Skull caps",
  "Weight room enhancements",
  "Coach and team gameday polos",
  "Team Tracker and Padilla Poll subscriptions",
  "Media day to highlight varsity players",
];

function SponsorshipTierCard({
  tier,
  size,
}: {
  tier: SponsorshipTier;
  size: "small" | "large";
}) {
  const dollars = Math.round(tier.price_cents / 100).toLocaleString("en-US");
  const isLarge = size === "large";
  // Flexible-price tiers (Custom) show the word "Flexible" instead of a dollar
  // figure; the tier name below already reads "Custom".
  const priceText = tier.price_flexible ? "Flexible" : `$${dollars}`;
  // Tiers with no perks (e.g. add-ons) show a summary body instead of a bullet
  // list. Their description holds the gray-italic subtitle and the body,
  // separated by a blank line; perk tiers use the whole description as subtitle.
  const isSummary = tier.perks.length === 0;
  const [summarySubtitle, ...summaryRest] = (tier.description ?? "").split(/\n{2,}/);
  const subtitle = isSummary ? summarySubtitle : tier.description;
  const summaryBody = summaryRest.join("\n\n");
  return (
    <div
      className={`relative bg-white border-2 rounded-lg flex flex-col ${
        tier.badge_label ? "border-mavs-green" : "border-mavs-navy/20"
      } ${isLarge ? "p-8" : "p-6"}`}
    >
      {tier.badge_label ? (
        <div className="absolute -top-3 right-4 bg-mavs-green text-white text-xs font-bold uppercase tracking-wider px-3 py-1 rounded-full">
          {tier.badge_label}
        </div>
      ) : null}
      <div className="text-center mb-4">
        <p
          className={`font-black text-mavs-navy ${
            isLarge ? "text-5xl" : "text-4xl"
          }`}
        >
          {priceText}
        </p>
        {tier.term_label ? (
          <p className="text-xs font-semibold uppercase tracking-wider text-gray-500 mt-1">
            {tier.term_label}
          </p>
        ) : null}
        <h3
          className={`font-bold uppercase text-mavs-navy mt-1 ${
            isLarge ? "text-2xl" : "text-xl"
          }`}
        >
          {tier.name}
        </h3>
        {subtitle ? (
          <p className="text-sm text-gray-600 italic mt-2">{subtitle}</p>
        ) : null}
      </div>
      {isSummary ? (
        summaryBody ? (
          <p className="flex-grow text-center text-base text-gray-700 leading-relaxed">
            {summaryBody}
          </p>
        ) : null
      ) : (
        <ul className="space-y-2 flex-grow">
          {tier.perks.map((perk, i) => (
            <li
              key={i}
              className={`flex gap-2 ${
                isLarge ? "text-base" : "text-sm"
              } text-gray-800`}
            >
              <span className="text-mavs-green font-bold">+</span>
              <span>{perk}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default async function BoostersSponsorPage() {
  // Copy editable per Jeremy 2026-05-23. Verbatim from initial draft; revisit with Kendra/board.
  const { current_year } = await getSiteSettingsCore();
  const supabase = createServerClient();

  const [tiersRes, sponsorsRes, mvpTierRes] = await Promise.all([
    supabase
      .from("sponsorship_tiers")
      .select(
        "id, name, price_cents, description, perks, sort_order, badge_label, year, is_addon, price_flexible, term_label",
      )
      .eq("year", current_year)
      .eq("active", true)
      .order("sort_order", { ascending: true }),
    supabase
      .from("sponsors")
      .select("id, name, logo_url, website_url, tier_id, sort_order, year")
      .eq("year", current_year)
      .eq("active", true)
      .order("sort_order", { ascending: true }),
    supabase
      .from("sponsorship_tiers")
      .select("id")
      .eq("year", current_year)
      .eq("active", true)
      .eq("name", "MVP")
      .maybeSingle(),
  ]);

  if (tiersRes.error) {
    console.error("[boosters/sponsor] tiers fetch failed", tiersRes.error);
  }
  if (sponsorsRes.error) {
    console.error("[boosters/sponsor] sponsors fetch failed", sponsorsRes.error);
  }
  if (mvpTierRes.error) {
    console.error("[boosters/sponsor] mvp tier fetch failed", mvpTierRes.error);
  }

  const tiers: SponsorshipTier[] = (tiersRes.data ?? []) as SponsorshipTier[];
  const sponsors: Sponsor[] = (sponsorsRes.data ?? []) as Sponsor[];
  const mvpTierId: string | null = mvpTierRes.data?.id ?? null;

  // Base levels vs add-ons, each ordered by sort_order (NOT price — Custom is
  // the final base choice and its $0/flexible price must not sort it first).
  const bySort = (a: SponsorshipTier, b: SponsorshipTier) =>
    a.sort_order - b.sort_order;
  const baseTiers = tiers.filter((t) => !t.is_addon).sort(bySort);
  const addOnTiers = tiers.filter((t) => t.is_addon).sort(bySort);

  const topTierSponsors = sponsors.filter((s) => s.tier_id === mvpTierId);
  const otherSponsors = sponsors.filter((s) => s.tier_id !== mvpTierId);

  return (
    <>
      {/* 1. Hero */}
      <section className="bg-mavs-navy text-white py-16 md:py-20">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-6xl font-black uppercase tracking-tight">
            Support McNeil Mavericks Football
          </h1>
          <div className="h-1 w-24 bg-mavs-green mx-auto mt-4"></div>
          <p className="text-xl md:text-2xl font-bold mt-6 max-w-3xl mx-auto">
            Every sponsorship directly supports the athletes in the McNeil
            Football program.
          </p>
        </div>
      </section>

      {/* 2. Mission statement */}
      <section className="container mx-auto px-4 py-16 md:py-20 max-w-3xl">
        <div className="space-y-6 text-lg leading-relaxed text-gray-800">
          <p>
            McNeil Mavericks Football is more than a team. It is a place where
            young men learn commitment, toughness, accountability, teamwork, and
            pride in representing their school and community.
          </p>
          <p>
            Our players put in countless hours before school, after school,
            during the summer, in the weight room, on the practice field, and
            under the Friday night lights. They give their time, energy, and
            heart to this program. As a Booster Club, our goal is to make sure
            they feel that same level of support from the community around them.
          </p>
          <p>
            Business sponsorships help provide the resources that make a real
            difference for our athletes throughout the season. Sponsor support
            helps fund team meals, banquets, extra equipment, player
            recognition, game day needs, travel support, and other
            football-specific expenses that help create a stronger, more
            meaningful experience for the young men in this program.
          </p>
          <p>
            When a business sponsors McNeil Football, it is doing more than
            advertising. It is standing behind local student-athletes. It is
            helping build school pride. It is showing families, fans, and
            players that this community believes in them.
          </p>
          <p>
            The McNeil Football Booster Club is a 501(c)(3) nonprofit
            organization, and we are grateful for the local businesses that
            choose to invest in our players and our program.
          </p>
          <p className="font-semibold text-mavs-navy">
            We invite you to partner with us this season and help support the
            McNeil Mavericks Football team.
          </p>
          <p>
            Your sponsorship matters. Your support is seen. And it directly
            impacts the athletes who wear the McNeil jersey.
          </p>
        </div>
        <div className="mt-10 text-center">
          <a
            href={SPONSORSHIP_LETTER_URL}
            className="inline-flex items-center gap-2 rounded-md border-2 border-mavs-navy px-6 py-3 font-bold uppercase text-mavs-navy hover:bg-mavs-navy hover:text-white transition-colors"
          >
            <Download className="h-5 w-5" />
            Download the Sponsorship Letter
          </a>
        </div>
      </section>

      {/* 2b. What sponsorship funds */}
      <section className="container mx-auto px-4 pb-16 md:pb-20 max-w-3xl">
        <div className="bg-mavs-navy/5 border-2 border-mavs-navy/10 rounded-lg p-8 md:p-10">
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy text-center">
            What Your Sponsorship Helps Fund
          </h2>
          <div className="h-1 w-20 bg-mavs-green mx-auto mt-3 mb-8"></div>
          <ul className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3">
            {SPONSORSHIP_FUNDS.map((item) => (
              <li
                key={item}
                className="flex gap-2 text-base text-gray-800"
              >
                <span className="text-mavs-green font-bold">+</span>
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* 3. Sponsorship Levels + tier cards */}
      <section className="container mx-auto px-4 py-12 md:py-16">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black uppercase tracking-tight text-mavs-navy">
            Sponsorship Levels
          </h2>
          <div className="h-1 w-20 bg-mavs-green mx-auto mt-3"></div>
          <p className="text-lg text-gray-600 mt-4 max-w-2xl mx-auto">
            Six sponsorship levels, plus add-ons. Every level supports McNeil
            football and puts your business in front of Mavs families all season
            long.
          </p>
        </div>

        {/* Base levels: responsive grid, ordered Blue → MVP → Custom */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {baseTiers.map((tier) => (
            <SponsorshipTierCard key={tier.id} tier={tier} size="small" />
          ))}
        </div>
      </section>

      {/* 3b. Add-Ons */}
      {addOnTiers.length > 0 ? (
        <section className="container mx-auto px-4 pb-12 md:pb-16">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-black uppercase tracking-tight text-mavs-navy">
              Add-Ons
            </h2>
            <div className="h-1 w-20 bg-mavs-green mx-auto mt-3"></div>
            <p className="text-lg text-gray-600 mt-4 max-w-2xl mx-auto">
              Add these to any sponsorship level, or take one on its own.
            </p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 max-w-3xl mx-auto">
            {addOnTiers.map((tier) => (
              <SponsorshipTierCard key={tier.id} tier={tier} size="small" />
            ))}
          </div>
        </section>
      ) : null}

      {/* 4. Contact CTA card */}
      <section className="container mx-auto px-4 py-12 md:py-16">
        <div className="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden max-w-3xl mx-auto">
          <div className="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight">
            Ready to Sponsor?
          </h2>
          <p className="text-lg text-white/90 mt-4 max-w-xl mx-auto">
            Reach out to the McNeil Football Booster Club and we&apos;ll get you
            set up at the level that&apos;s right for your business.
          </p>
          <a
            href="mailto:fundraising@mcneilmavericks.org?subject=McNeil%20Football%20Sponsorship%20Inquiry"
            className="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg"
          >
            Email Us to Become a Sponsor
          </a>
          <p className="text-sm text-white/70 mt-4">
            fundraising@mcneilmavericks.org
          </p>
        </div>
      </section>

      {/* 5. Sponsor strip */}
      {sponsors.length > 0 ? (
        <section className="container mx-auto px-4 py-12 md:py-16 border-t-2 border-mavs-green/30">
          <h2 className="text-2xl md:text-3xl font-bold text-mavs-navy text-center mb-10">
            Thank You to Our {current_year.replace("-", "-20")} Sponsors!
          </h2>

          {topTierSponsors.length > 0 ? (
            <div className="flex flex-wrap items-center justify-center gap-12 mb-8">
              {topTierSponsors.map((s) => (
                <SponsorStripLogo
                  key={s.id}
                  sponsor={s}
                  sizeClass="max-w-[220px] max-h-20"
                />
              ))}
            </div>
          ) : null}

          {otherSponsors.length > 0 ? (
            <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
              {otherSponsors.map((s) => (
                <SponsorStripLogo
                  key={s.id}
                  sponsor={s}
                  sizeClass="max-w-[160px] max-h-12"
                />
              ))}
            </div>
          ) : null}

          <div className="text-center mt-10">
            <Link
              href="/sponsors"
              className="text-mavs-navy font-semibold uppercase tracking-wide text-sm hover:text-mavs-green transition-colors"
            >
              See All Sponsors →
            </Link>
          </div>
        </section>
      ) : null}
    </>
  );
}

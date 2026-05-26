// /boosters/join is the one page that intentionally deviates from the
// navy-primary brand pass: the banner is solid green (#1E541E) to match
// the board-ratified PDF (docs/2026 - 2027 Membership - McNeil HS
// Football Boosters.pdf). Documented in docs/specs/boosters_join_spec.md
// section "1. Banner".
//
// Booster year, not football year: this page reads
// site_settings.current_board_year. current_year governs football data
// (rosters, games, coaches) and is currently '2025-26' — using it here
// would silently render the empty state.

import Image from "next/image";

import { BOOSTER_FORM_URL } from "@/lib/constants";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { MembershipTier } from "@/lib/types";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Become a Booster — McNeil Mavericks Football",
};

async function loadTiers(year: string): Promise<MembershipTier[]> {
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("membership_tiers")
      .select(
        "id, name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label, active",
      )
      .eq("year", year)
      .eq("active", true)
      .order("sort_order", { ascending: true })
      .returns<MembershipTier[]>();
    if (error || !data) {
      console.error("[boosters/join] failed to load membership_tiers", error);
      return [];
    }
    return data;
  } catch (e) {
    console.error("[boosters/join] threw loading membership_tiers", e);
    return [];
  }
}

function priceLabel(cents: number): string {
  return `$${Math.round(cents / 100)}`;
}

export default async function BoostersJoinPage() {
  const { current_board_year: boardYear } = await getSiteSettingsCore();
  const tiers = await loadTiers(boardYear);

  if (tiers.length === 0) {
    return (
      <main className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-16">
        <p className="text-foreground">
          Booster membership for the {boardYear} season will open soon. Check
          back.
        </p>
      </main>
    );
  }

  return (
    <main>
      {/* 1. Banner */}
      <section
        className="bg-[#1E541E] text-white"
        aria-label="Booster club banner"
      >
        <div className="mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 py-8 sm:py-10 md:py-12 min-h-[140px] md:min-h-[160px] flex flex-col md:flex-row items-center md:items-center gap-4 md:gap-6 relative">
          <Image
            src="/brand/mhs-logo.png"
            alt=""
            width={96}
            height={96}
            priority
            className="h-16 w-16 md:h-20 md:w-20 object-contain shrink-0"
          />
          <h1 className="flex-1 text-center text-2xl sm:text-3xl md:text-4xl font-black uppercase tracking-wide leading-tight">
            McNeil High School Football Booster Club
          </h1>
          <span
            className="hidden md:block absolute top-3 right-4 text-sm font-bold tracking-wide"
            aria-hidden="true"
          >
            {boardYear}
          </span>
          {/* Mobile: year below the title (banner stack already centered) */}
          <span className="md:hidden text-sm font-bold tracking-wide">
            {boardYear}
          </span>
        </div>
      </section>

      {/* 2. Intro */}
      <section className="mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 pt-10 pb-6">
        <h2 className="text-xl sm:text-2xl font-bold uppercase tracking-tight text-mavs-navy">
          Be a Mavs Booster!
        </h2>
        <p className="mt-3 text-foreground max-w-3xl">
          Sign up today and get ready for the {boardYear} McNeil Mavericks
          Football Season. Thank you for supporting the MAVS!
        </p>
      </section>

      {/* 3. Tier grid */}
      <section
        className="mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 pb-12"
        aria-label="Membership tiers"
      >
        <ul className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 list-none p-0">
          {tiers.map((tier, i) => {
            const badged = tier.badge_label !== null;
            const isLast = i === tiers.length - 1;
            // Generic orphan centering: if the last card is alone in its row
            // at md (2-col) or lg (3-col), center it. Self-heals if the
            // tier count changes. gap-6 = 1.5rem, so a one-column width at
            // md is calc(50% - 0.75rem). At lg, override the md hacks and
            // just shift to column 2.
            const mdOrphan = isLast && tiers.length % 2 === 1;
            const lgOrphan = isLast && tiers.length % 3 === 1;
            const orphanClasses = [
              mdOrphan &&
                "md:col-span-2 md:max-w-[calc(50%-0.75rem)] md:mx-auto",
              lgOrphan &&
                "lg:col-start-2 lg:col-span-1 lg:max-w-none lg:mx-0",
            ]
              .filter(Boolean)
              .join(" ");
            return (
              <li
                key={tier.id}
                className={
                  "relative flex flex-col rounded-lg bg-white p-5 " +
                  (badged
                    ? "border-2 border-mavs-green shadow-sm "
                    : "border border-mavs-navy ") +
                  orphanClasses
                }
              >
                {badged ? (
                  <span className="absolute -top-3 right-4 rounded-full bg-mavs-green px-3 py-1 text-xs font-bold uppercase tracking-wide text-white">
                    {tier.badge_label}
                  </span>
                ) : null}
                <h3 className="text-lg sm:text-xl font-black text-mavs-navy">
                  {priceLabel(tier.price_cents)} {tier.name}
                </h3>
                {tier.description ? (
                  <p className="mt-2 text-sm text-gray-700">
                    {tier.description}
                  </p>
                ) : null}
                {tier.perks.length > 0 ? (
                  <ul className="mt-3 flex-1 list-none p-0 space-y-1 text-sm text-foreground">
                    {tier.perks.map((perk, i) => (
                      <li key={i}>+ {perk}</li>
                    ))}
                  </ul>
                ) : null}
                <a
                  href={BOOSTER_FORM_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-5 inline-flex w-full items-center justify-center rounded-md bg-mavs-navy px-4 py-2.5 text-sm font-bold uppercase tracking-wide text-white hover:bg-mavs-navy-dark transition-colors"
                >
                  Join at {tier.name}
                  <span className="sr-only"> (opens in new tab)</span>
                </a>
              </li>
            );
          })}
        </ul>
      </section>

      {/* 4. Closing */}
      <section className="mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 pb-16 text-center">
        <h2 className="text-3xl sm:text-4xl md:text-5xl font-black uppercase tracking-tight text-mavs-green">
          Go Mavs!
        </h2>
        <p className="mt-4 text-sm text-muted-foreground">
          Questions? Contact{" "}
          <a
            href="mailto:mcneilfootballboosters@gmail.com"
            className="text-mavs-navy hover:underline"
          >
            mcneilfootballboosters@gmail.com
          </a>
          .
        </p>
      </section>
    </main>
  );
}

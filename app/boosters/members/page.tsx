// Public booster members + top-donor recognition page.
//
// Data:
//   - membership_tiers from Supabase (DB, current_board_year, active=true)
//   - Form-responses rows from Google Sheets via lib/sheets/boosters.ts
// Privacy contract: names shown as "First L." (e.g. "Sarah V."). The source
//   Google Form has no public-listing opt-in, so the first-name + last-initial
//   format is the conservative default. Manual opt-out via email.
// Filter: any sheet row with a tier selected. Payable Status is intentionally
//   ignored per Jeremy 2026-05-18 ("include all on the list, someone can
//   manually remove or move to free tier if they haven't paid").
// Top-donor selection: top 3 tiers by sort_order (self-heals if tier set
//   changes). With migration 034: Touchdown! / Playoffs! / Championship!.

import Link from "next/link";

import { getSiteSettingsCore } from "@/lib/site-settings";
import {
  getBoosterMembers,
  type BoosterMemberRow,
} from "@/lib/sheets/boosters";
import { createServerClient } from "@/lib/supabase/server";
import type { MembershipTier } from "@/lib/types";

export const revalidate = 300; // 5 min ISR

export const metadata = {
  title: "Boosters — McNeil Mavericks Football",
};

interface TierGroup {
  tier: MembershipTier;
  members: BoosterMemberRow[];
}

async function loadTiersForYear(year: string): Promise<MembershipTier[]> {
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
      console.error("[boosters/members] tier fetch failed", error);
      return [];
    }
    return data;
  } catch (e) {
    console.error("[boosters/members] tier fetch threw", e);
    return [];
  }
}

function displayName(m: BoosterMemberRow): string {
  if (m.parent1Short && m.parent2Short)
    return `${m.parent1Short} & ${m.parent2Short}`;
  return m.parent1Short ?? m.parent2Short ?? "—";
}

function groupByTier(
  tiers: MembershipTier[],
  rows: BoosterMemberRow[],
): TierGroup[] {
  const byName = new Map<string, BoosterMemberRow[]>();
  for (const r of rows) {
    if (!byName.has(r.tierName)) byName.set(r.tierName, []);
    byName.get(r.tierName)!.push(r);
  }
  return tiers
    .slice()
    .sort((a, b) => b.sort_order - a.sort_order)
    .map((tier) => ({
      tier,
      members: (byName.get(tier.name) ?? [])
        .slice()
        .sort((a, b) => displayName(a).localeCompare(displayName(b))),
    }));
}

export default async function BoostersMembersPage() {
  const { current_board_year: boardYear } = await getSiteSettingsCore();
  const [tiers, sheetRows] = await Promise.all([
    loadTiersForYear(boardYear),
    getBoosterMembers(),
  ]);
  const groups = groupByTier(tiers, sheetRows);
  const visibleGroups = groups.filter((g) => g.members.length > 0);
  const totalMembers = sheetRows.length;

  // Top 3 tiers by sort_order. Self-heals if active tiers change.
  const topTierIds = new Set(
    tiers
      .slice()
      .sort((a, b) => b.sort_order - a.sort_order)
      .slice(0, 3)
      .map((t) => t.id),
  );
  const topGroups = visibleGroups.filter((g) => topTierIds.has(g.tier.id));

  return (
    <main>
      {/* Hero */}
      <section className="bg-mavs-navy text-white">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12 md:py-16 text-center">
          <p className="text-xs sm:text-sm font-bold uppercase tracking-[0.2em] text-mavs-green">
            {boardYear} Boosters
          </p>
          <h1 className="mt-3 text-4xl sm:text-5xl md:text-6xl font-black uppercase tracking-tight">
            Our Supporters
          </h1>
          <p className="mt-5 max-w-2xl mx-auto text-base sm:text-lg text-white/90">
            {totalMembers > 0
              ? `Thank you to the ${totalMembers} families who power Mavericks football.`
              : "Thank you to everyone who powers Mavericks football."}
          </p>
        </div>
      </section>

      {/* Privacy note */}
      <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 pt-6 pb-2">
        <p className="text-xs italic text-muted-foreground">
          Names shown as first name + last initial. Want yours updated or
          removed?{" "}
          <a
            href="mailto:boosters@mcneilmavericks.org"
            className="text-mavs-navy hover:underline not-italic font-semibold"
          >
            Email us
          </a>
          .
        </p>
      </section>

      {/* All-members list */}
      {visibleGroups.length === 0 ? (
        <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12 text-center">
          <p className="text-foreground">
            We&apos;re building our {boardYear} member list.
          </p>
          <p className="mt-3">
            <Link
              href="/boosters/join"
              className="text-mavs-navy font-bold hover:underline"
            >
              Be the first to join →
            </Link>
          </p>
        </section>
      ) : (
        <section
          className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-8 space-y-12"
          aria-label="Members by tier"
        >
          {visibleGroups.map((group) => (
            <div key={group.tier.id}>
              <header className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-b-2 border-mavs-navy pb-2 mb-4">
                <div className="flex items-baseline gap-3">
                  <h2 className="text-xl sm:text-2xl font-black uppercase tracking-tight text-mavs-navy">
                    {group.tier.name}
                  </h2>
                  {group.tier.badge_label ? (
                    <span className="rounded-full bg-mavs-green px-2 py-0.5 text-[0.65rem] font-bold uppercase tracking-wide text-white">
                      {group.tier.badge_label}
                    </span>
                  ) : null}
                </div>
                <p className="text-xs sm:text-sm font-bold text-muted-foreground">
                  ${Math.round(group.tier.price_cents / 100)} ·{" "}
                  {group.members.length}{" "}
                  {group.members.length === 1 ? "supporter" : "supporters"}
                </p>
              </header>
              <ul className="columns-2 sm:columns-3 lg:columns-4 gap-x-6 list-none p-0 text-foreground">
                {group.members.map((m, i) => (
                  <li
                    key={`${group.tier.id}-${i}`}
                    className="break-inside-avoid py-1 text-sm"
                  >
                    {displayName(m)}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </section>
      )}

      {/* Special Thanks (top 3 tiers, only if any have members) */}
      {topGroups.length > 0 ? (
        <section
          className="bg-mavs-navy/5 mt-8 border-t border-mavs-navy/10"
          aria-label="Special thanks to top donors"
        >
          <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-16">
            <div className="text-center mb-10">
              <p className="text-xs sm:text-sm font-bold uppercase tracking-[0.2em] text-mavs-green">
                Special Thanks
              </p>
              <h2 className="mt-3 text-3xl sm:text-4xl md:text-5xl font-black uppercase tracking-tight text-mavs-navy">
                Top Donors
              </h2>
              <p className="mt-4 max-w-xl mx-auto text-foreground">
                These families go all-in for the program at our highest
                membership levels.
              </p>
            </div>
            <div className="space-y-6">
              {topGroups.map((group) => (
                <article
                  key={`top-${group.tier.id}`}
                  className="rounded-lg border-2 border-mavs-green bg-white p-6 shadow-sm"
                >
                  <header className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 mb-4">
                    <h3 className="text-2xl sm:text-3xl font-black uppercase tracking-tight text-mavs-navy">
                      {group.tier.name}
                    </h3>
                    <p className="text-sm font-bold text-muted-foreground">
                      ${Math.round(group.tier.price_cents / 100)} · level
                    </p>
                  </header>
                  <ul className="columns-1 sm:columns-2 gap-x-6 list-none p-0">
                    {group.members.map((m, i) => (
                      <li
                        key={`top-${group.tier.id}-${i}`}
                        className="break-inside-avoid py-1 text-lg font-semibold text-foreground"
                      >
                        {displayName(m)}
                      </li>
                    ))}
                  </ul>
                </article>
              ))}
            </div>
          </div>
        </section>
      ) : null}

      {/* CTA */}
      <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12 text-center">
        <p className="text-foreground">
          Not yet a member?{" "}
          <Link
            href="/boosters/join"
            className="text-mavs-navy font-bold hover:underline"
          >
            Join the Boosters →
          </Link>
        </p>
      </section>
    </main>
  );
}

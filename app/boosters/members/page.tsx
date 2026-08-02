// Public booster members page.
//
// Data: dedup'd sheet rows from lib/sheets/boosters.ts. Tier metadata from
// Supabase is still used to derive the Top Donors set (top 3 tiers by
// sort_order, self-healing), but tier grouping is intentionally NOT shown
// in the main list per 2026-05-19 polish pass.
//
// Privacy contract: names shown as "First L.". The Google Form has no
// public-listing opt-in; this format is the conservative default. Opt-out
// path is a plain-text contact line in the closing block (the explanatory
// "names shown as..." line was removed per polish pass; format speaks for
// itself).
//
// Filter: dedup'd by email (latest-timestamp wins); any row with a tier
// selected is included. Payable Status is ignored.
//
// Sort: alphabetical by Parent 1 surname (split on last whitespace, so
// "Sarah Van Buren" sorts under "Buren"). Couples with different surnames
// sort under Parent 1's surname.

import Link from "next/link";

import { Button } from "@/components/ui/button";
import { BOOSTER_FORM_URL } from "@/lib/constants";
import {
  getBoosterMembers,
  type BoosterMemberRow,
} from "@/lib/sheets/boosters";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { MembershipTier } from "@/lib/types";

export const revalidate = 300; // 5 min ISR

export const metadata = {
  title: "Members — McNeil Mavericks Football",
};

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

/**
 * Alphabetical by Parent 1 surname, then full display name for stability.
 *
 * Households where Parent 1 gave no surname sort to the END of the list rather
 * than under their first name (`parent1Surname` is "" for those). Parent 2's
 * surname is deliberately NOT used as a fallback sort key: the parents may have
 * different surnames, so borrowing one would file a person under a name that
 * isn't theirs.
 */
function compareByLastName(a: BoosterMemberRow, b: BoosterMemberRow): number {
  const aHasSurname = a.parent1Surname.length > 0;
  const bHasSurname = b.parent1Surname.length > 0;
  if (aHasSurname !== bHasSurname) return aHasSurname ? -1 : 1;
  const surnameCmp = a.parent1Surname
    .toLowerCase()
    .localeCompare(b.parent1Surname.toLowerCase());
  if (surnameCmp !== 0) return surnameCmp;
  return displayName(a)
    .toLowerCase()
    .localeCompare(displayName(b).toLowerCase());
}

export default async function BoostersMembersPage() {
  const { current_board_year: boardYear } = await getSiteSettingsCore();
  const [tiers, members] = await Promise.all([
    loadTiersForYear(boardYear),
    getBoosterMembers(boardYear),
  ]);

  const totalMembers = members.length;
  const sortedMembers = members.slice().sort(compareByLastName);

  // Top 3 tier names by sort_order DESC. Self-heals if the active tier set
  // changes (and stays consistent with /boosters/join's tier ladder).
  const topTierNames = new Set(
    tiers
      .slice()
      .sort((a, b) => b.sort_order - a.sort_order)
      .slice(0, 3)
      .map((t) => t.name),
  );
  const topDonors = sortedMembers.filter((m) => topTierNames.has(m.tierName));

  return (
    <main>
      {/* Hero */}
      <section className="bg-mavs-navy text-white">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12 md:py-16 text-center">
          <p className="text-xs sm:text-sm font-bold uppercase tracking-[0.2em] text-white">
            {boardYear} Boosters
          </p>
          <h1 className="mt-3 text-4xl sm:text-5xl md:text-6xl font-black uppercase tracking-tight">
            Members
          </h1>
          <p className="mt-5 max-w-2xl mx-auto text-base sm:text-lg text-white/90">
            {totalMembers > 0
              ? `Thank you to the ${totalMembers} families who power Mavericks football.`
              : "Thank you to everyone who powers Mavericks football."}
          </p>
          <div className="mt-8 flex justify-center">
            <Button
              size="lg"
              nativeButton={false}
              className="bg-white text-mavs-navy hover:bg-white/90"
              render={<Link href="/boosters/join" />}
            >
              JOIN THE CLUB! →
            </Button>
          </div>
        </div>
      </section>

      {/* Main list: flat alphabetical, no tier grouping. Names are the visual
          anchor — match tier-card h3 typography from /boosters/join. */}
      {sortedMembers.length === 0 ? (
        <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-16 text-center">
          <p className="text-foreground">
            We&apos;re building our {boardYear} member list.
          </p>
          <p className="mt-3">
            <a
              href={BOOSTER_FORM_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-mavs-navy font-bold hover:underline"
            >
              Be the first to join →
              <span className="sr-only"> (opens in new tab)</span>
            </a>
          </p>
        </section>
      ) : (
        <section
          className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12"
          aria-label="Members"
        >
          <ul className="columns-1 sm:columns-2 lg:columns-3 gap-x-10 list-none p-0">
            {sortedMembers.map((m, i) => (
              <li
                key={`member-${i}`}
                className="break-inside-avoid py-1.5 text-lg sm:text-xl font-black uppercase tracking-tight text-mavs-navy leading-snug"
              >
                {displayName(m)}
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* Top Donors — flat alphabetical name list on the McNeil green band.
          Column count scales with the donor count: 1 -> 1 centered, 2 -> 2,
          3+ -> 3 columns. Container is max-w-3xl so a sparse N=2 doesn't
          spread to opposite page edges. */}
      {topDonors.length > 0 ? (
        <section className="bg-mavs-green text-white" aria-label="Top donors">
          <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-16 text-center">
            <p className="text-xs sm:text-sm font-bold uppercase tracking-[0.2em] text-white">
              Special Thanks
            </p>
            <h2 className="mt-3 text-3xl sm:text-4xl md:text-5xl font-black uppercase tracking-tight text-white">
              Top Donors
            </h2>
            <ul
              className={
                "mt-10 grid gap-x-12 gap-y-3 list-none p-0 max-w-3xl mx-auto " +
                (topDonors.length === 1
                  ? "grid-cols-1"
                  : topDonors.length === 2
                    ? "grid-cols-1 sm:grid-cols-2"
                    : "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3")
              }
            >
              {topDonors.map((m, i) => (
                <li
                  key={`top-${i}`}
                  className="py-1.5 text-lg sm:text-xl font-black uppercase tracking-tight text-white leading-snug"
                >
                  {displayName(m)}
                </li>
              ))}
            </ul>
          </div>
        </section>
      ) : null}

      {/* Closing block: Join CTA → Form, then plain-text opt-out line. */}
      <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12 text-center space-y-3">
        <p className="text-foreground">
          Not yet a member?{" "}
          <a
            href={BOOSTER_FORM_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-mavs-navy font-bold hover:underline"
          >
            Join the Boosters →
            <span className="sr-only"> (opens in new tab)</span>
          </a>
        </p>
        <p className="text-sm text-muted-foreground">
          Want yours updated or removed? Email us{" "}
          <a
            href="mailto:membership@mcneilmavericks.org"
            className="text-mavs-navy hover:underline"
          >
            membership@mcneilmavericks.org
          </a>
        </p>
      </section>
    </main>
  );
}

import "server-only";

import { createServerClient } from "@/lib/supabase/server";

export type CommunityPartner = {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
};

/**
 * Businesses that give in-kind support (meals, gift cards, product) rather than
 * buying a sponsorship level. Migration 115.
 *
 * The three sponsor-facing surfaces (app/page.tsx, app/sponsors/page.tsx,
 * app/boosters/sponsor/page.tsx) each filter `kind = 'sponsor'`, so a pure
 * in-kind supporter can never be published as if they had paid for a tier.
 *
 * ⚠️ Those surfaces must NOT learn about `provides_in_kind`. That flag only ever
 * ADDS a business to this list; it never moves one onto the sponsor surfaces.
 * A business that both pays and gives in kind (Rudy's) correctly appears in
 * both places, which is the point of it being a separate column from `kind`.
 *
 * ⚠️ No description/tagline is selected, deliberately. The club is a 501(c)(3);
 * name + logo + link is acknowledgment, while promotional copy would make it
 * advertising. Don't add one.
 */
export async function getCommunityPartners(
  year: string,
): Promise<CommunityPartner[]> {
  const supabase = createServerClient();
  const { data, error } = await supabase
    .from("sponsors")
    .select("id, name, logo_url, website_url")
    // A business qualifies either because in-kind support is ALL they give
    // (kind = community_partner), or because they also give in kind on top of a
    // paid sponsorship (provides_in_kind) — Rudy's is both a Scoreboard sponsor
    // and a meal provider. PostgREST `or` keeps this one round trip.
    .or("kind.eq.community_partner,provides_in_kind.is.true")
    .eq("active", true)
    .eq("year", year)
    // Name only — deliberately NOT sort_order. Partners are unranked by design
    // (that is the point of having no levels here), and sort_order on this table
    // exists to drive the homepage carousel's pinned-first order. Honouring it
    // here would drag Rudy's, pinned at 1 for the carousel, out of alphabetical
    // position among the partners. Two orderings, two purposes.
    .order("name", { ascending: true });

  if (error) {
    console.error("[queries/sponsors] getCommunityPartners failed", error);
    return [];
  }
  return (data ?? []) as CommunityPartner[];
}

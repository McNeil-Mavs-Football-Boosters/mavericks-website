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
 * These render ONLY on /boosters/donate. The three sponsor-facing surfaces
 * (app/page.tsx, app/sponsors/page.tsx, app/boosters/sponsor/page.tsx) each
 * filter `kind = 'sponsor'` so a partner can never be published as if they had
 * paid for a tier.
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
    .eq("kind", "community_partner")
    .eq("active", true)
    .eq("year", year)
    .order("sort_order", { ascending: true })
    .order("name", { ascending: true });

  if (error) {
    console.error("[queries/sponsors] getCommunityPartners failed", error);
    return [];
  }
  return (data ?? []) as CommunityPartner[];
}

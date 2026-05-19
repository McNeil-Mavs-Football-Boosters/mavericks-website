import { createServerClient } from "@/lib/supabase/server";
import type { SiteSettings } from "@/lib/types";

export type HeroFields = Pick<
  SiteSettings,
  | "hero_image_url"
  | "hero_headline"
  | "hero_subhead"
  | "primary_cta_label"
  | "primary_cta_url"
>;

export const HERO_DEFAULTS: HeroFields = {
  hero_image_url: null,
  hero_headline: "McNeil Mavericks Football",
  hero_subhead: "Home of the McNeil Mavericks · Austin, TX",
  primary_cta_label: "Join the Booster Club",
  primary_cta_url: "/boosters/join",
};

export function mergeHero(
  data: Partial<HeroFields> | null | undefined,
): HeroFields {
  if (!data) return HERO_DEFAULTS;
  return {
    hero_image_url: data.hero_image_url ?? null,
    hero_headline: data.hero_headline || HERO_DEFAULTS.hero_headline,
    hero_subhead: data.hero_subhead ?? HERO_DEFAULTS.hero_subhead,
    primary_cta_label:
      data.primary_cta_label || HERO_DEFAULTS.primary_cta_label,
    primary_cta_url: data.primary_cta_url || HERO_DEFAULTS.primary_cta_url,
  };
}

export async function loadHero(): Promise<HeroFields> {
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("site_settings")
      .select(
        "hero_image_url, hero_headline, hero_subhead, primary_cta_label, primary_cta_url",
      )
      .eq("id", 1)
      .single<HeroFields>();
    return error ? HERO_DEFAULTS : mergeHero(data);
  } catch {
    return HERO_DEFAULTS;
  }
}

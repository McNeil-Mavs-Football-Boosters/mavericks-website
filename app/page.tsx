import Image from "next/image";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import { createServerClient } from "@/lib/supabase/server";
import type { SiteSettings } from "@/lib/types";

export const revalidate = 60;

type HeroFields = Pick<
  SiteSettings,
  | "hero_image_url"
  | "hero_headline"
  | "hero_subhead"
  | "primary_cta_label"
  | "primary_cta_url"
>;

const HERO_DEFAULTS: HeroFields = {
  hero_image_url: null,
  hero_headline: "McNeil Mavericks Football Booster Club",
  hero_subhead: null,
  primary_cta_label: "Join the Club",
  primary_cta_url: "/join",
};

async function loadHero(): Promise<HeroFields> {
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("site_settings")
      .select(
        "hero_image_url, hero_headline, hero_subhead, primary_cta_label, primary_cta_url",
      )
      .eq("id", 1)
      .single<HeroFields>();
    if (error || !data) return HERO_DEFAULTS;
    return {
      hero_image_url: data.hero_image_url ?? null,
      hero_headline: data.hero_headline || HERO_DEFAULTS.hero_headline,
      hero_subhead: data.hero_subhead ?? null,
      primary_cta_label:
        data.primary_cta_label || HERO_DEFAULTS.primary_cta_label,
      primary_cta_url: data.primary_cta_url || HERO_DEFAULTS.primary_cta_url,
    };
  } catch {
    return HERO_DEFAULTS;
  }
}

export default async function Home() {
  const hero = await loadHero();
  const hasHeroImage = Boolean(hero.hero_image_url);

  return (
    <>
      <section
        className={`relative isolate w-full min-h-[60vh] md:min-h-[70vh] flex items-center justify-center text-center text-white ${
          hasHeroImage ? "" : "bg-mavs-green"
        }`}
      >
        {hasHeroImage && hero.hero_image_url ? (
          <>
            <Image
              src={hero.hero_image_url}
              alt=""
              fill
              priority
              className="object-cover -z-10"
            />
            <div
              className="absolute inset-0 -z-10 bg-black/50"
              aria-hidden="true"
            />
          </>
        ) : null}

        <div className="mx-auto max-w-3xl px-6 py-24">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
            {hero.hero_headline}
          </h1>
          {hero.hero_subhead ? (
            <p className="mt-4 text-lg sm:text-xl text-white/90">
              {hero.hero_subhead}
            </p>
          ) : null}
          <div className="mt-8 flex justify-center">
            <Button
              size="lg"
              nativeButton={false}
              className="bg-white text-mavs-green hover:bg-white/90"
              render={<Link href={hero.primary_cta_url} />}
            >
              {hero.primary_cta_label}
            </Button>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-3xl px-6 py-16">
        <p className="text-base leading-7 text-foreground">
          The McNeil Maverick Football Booster Club is a parent-run 501(c)(3)
          supporting the football program at McNeil High School in Austin,
          Texas. We fundraise, organize events, recognize seniors, and back the
          coaching staff so the team can focus on football. Every Mavs family
          is welcome — whether you can give a dollar, a few hours, or a
          season.
        </p>
        <p className="mt-4">
          <Link
            href="/about"
            className="text-mavs-green font-medium hover:underline"
          >
            Learn more about the booster club →
          </Link>
        </p>
      </section>
    </>
  );
}

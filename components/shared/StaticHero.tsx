import Image from "next/image";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import type { HeroFields } from "@/lib/hero";

type StaticHeroProps = {
  hero: HeroFields;
};

export function StaticHero({ hero }: StaticHeroProps) {
  const hasHeroImage = Boolean(hero.hero_image_url);

  return (
    <section
      className={`relative isolate w-full flex items-center justify-center text-center text-white ${
        hasHeroImage ? "" : "bg-mavs-navy"
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

      <div className="mx-auto max-w-3xl px-6 py-12 md:py-16">
        <h1 className="text-4xl font-black uppercase tracking-tight sm:text-5xl md:text-6xl">
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
            className="bg-white text-mavs-navy hover:bg-white/90"
            render={<Link href={hero.primary_cta_url} />}
          >
            {hero.primary_cta_label}
          </Button>
        </div>
      </div>
    </section>
  );
}

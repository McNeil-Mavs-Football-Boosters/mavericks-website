"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { publicStorageUrl } from "@/lib/storage";
import type {
  HeadlineCtaPayload,
  HeroBackgroundImage,
  HeroForegroundTile,
  SponsorSpotlightPayload,
} from "@/lib/types";

type HeroCarouselProps = {
  backgrounds: HeroBackgroundImage[];
  tiles: HeroForegroundTile[];
};

type ActivePool = "cta" | "sponsor";

const BG_INTERVAL_MS = 6000;
const FG_INTERVAL_MS = 4000;

// Anchor for each background's `object-cover` crop, per row (migration 187).
//
// ⚠️ THESE MUST STAY WRITTEN OUT AS LITERAL STRINGS. Tailwind v4 emits only the
// classes it can SEE in the source, so `object-${bg.object_position}` compiles
// to nothing and the photo silently falls back to the browser default (50% 50%)
// with no error anywhere. A lookup table is the fix, not a template string.
//
// Keys match the DB CHECK constraint on hero_background_images.object_position.
// Adding a fourth anchor means adding it in BOTH places.
const HERO_OBJECT_POSITION = {
  top: "object-top",
  center: "object-center",
  bottom: "object-bottom",
} as const;

// Fallback matches the class that was hardcoded here before 187, so a row
// written by something that does not know about the column renders as it always
// did rather than jumping to centre.
const HERO_OBJECT_POSITION_FALLBACK = "object-top";

export function HeroCarousel({ backgrounds, tiles }: HeroCarouselProps) {
  const { ctaTiles, sponsorTiles } = useMemo(() => {
    const cta: HeroForegroundTile[] = [];
    const sponsor: HeroForegroundTile[] = [];
    for (const tile of tiles) {
      if (tile.tile_type === "headline_cta") cta.push(tile);
      else if (tile.tile_type === "sponsor_spotlight") sponsor.push(tile);
    }
    return { ctaTiles: cta, sponsorTiles: sponsor };
  }, [tiles]);

  const [bgIndex, setBgIndex] = useState(0);
  const [ctaIndex, setCtaIndex] = useState(0);
  const [sponsorIndex, setSponsorIndex] = useState(0);
  const [activePool, setActivePool] = useState<ActivePool>(() =>
    ctaTiles.length > 0 ? "cta" : "sponsor",
  );
  const [isHidden, setIsHidden] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);

  // Track prefers-reduced-motion and respond to OS-level toggles mid-session.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReducedMotion(mql.matches);
    const onChange = (event: MediaQueryListEvent) => {
      setReducedMotion(event.matches);
    };
    mql.addEventListener("change", onChange);
    return () => {
      mql.removeEventListener("change", onChange);
    };
  }, []);

  // Page Visibility — pause when tab is hidden.
  useEffect(() => {
    if (typeof document === "undefined") return;
    const onVisibilityChange = () => {
      setIsHidden(document.visibilityState === "hidden");
    };
    onVisibilityChange();
    document.addEventListener("visibilitychange", onVisibilityChange);
    return () => {
      document.removeEventListener("visibilitychange", onVisibilityChange);
    };
  }, []);

  const shouldAnimate = !reducedMotion && !isHidden;

  // Background rotation — independent of foreground.
  useEffect(() => {
    if (!shouldAnimate) return;
    if (backgrounds.length <= 1) return;
    const id = window.setInterval(() => {
      setBgIndex((i) => (i + 1) % backgrounds.length);
    }, BG_INTERVAL_MS);
    return () => {
      window.clearInterval(id);
    };
  }, [shouldAnimate, backgrounds.length]);

  // Foreground rotation — two-pool alternation.
  useEffect(() => {
    if (!shouldAnimate) return;
    const totalTiles = ctaTiles.length + sponsorTiles.length;
    if (totalTiles <= 1) return;
    const id = window.setInterval(() => {
      setActivePool((pool) => {
        if (pool === "cta") {
          if (sponsorTiles.length > 0) {
            return "sponsor";
          }
          // No sponsors — stay in cta and advance.
          setCtaIndex((i) => (i + 1) % ctaTiles.length);
          return "cta";
        }
        // Leaving sponsor: advance sponsor pointer first.
        setSponsorIndex((i) => (i + 1) % sponsorTiles.length);
        if (ctaTiles.length > 0) {
          setCtaIndex((i) => (i + 1) % ctaTiles.length);
          return "cta";
        }
        return "sponsor";
      });
    }, FG_INTERVAL_MS);
    return () => {
      window.clearInterval(id);
    };
  }, [shouldAnimate, ctaTiles.length, sponsorTiles.length]);

  const hasBackgrounds = backgrounds.length > 0;
  const hasTiles = ctaTiles.length > 0 || sponsorTiles.length > 0;
  const showScrim = hasBackgrounds && hasTiles;

  const currentTile: HeroForegroundTile | null = hasTiles
    ? activePool === "cta" && ctaTiles.length > 0
      ? ctaTiles[ctaIndex] ?? null
      : sponsorTiles.length > 0
        ? sponsorTiles[sponsorIndex] ?? null
        : (ctaTiles[ctaIndex] ?? null)
    : null;

  return (
    <section
      className={`relative isolate w-full min-h-[55vh] md:min-h-[77vh] overflow-hidden ${
        hasBackgrounds ? "" : "bg-mavs-navy"
      }`}
    >
      {hasBackgrounds
        ? backgrounds.map((bg, idx) => (
            <div
              key={bg.id}
              className={`absolute inset-0 transition-opacity duration-1000 ${
                idx === bgIndex ? "opacity-100" : "opacity-0"
              }`}
              aria-hidden={idx === bgIndex ? undefined : true}
            >
              <Image
                src={publicStorageUrl(bg.storage_path)}
                alt={bg.alt_text}
                fill
                sizes="100vw"
                priority={idx === 0}
                className={`object-cover ${
                  HERO_OBJECT_POSITION[bg.object_position] ??
                  HERO_OBJECT_POSITION_FALLBACK
                }`}
              />
            </div>
          ))
        : null}

      {showScrim ? (
        <div
          className="absolute inset-0 bg-gradient-to-t from-black/55 to-black/25"
          aria-hidden="true"
        />
      ) : null}

      {currentTile ? (
        <div className="relative z-10 flex min-h-[55vh] md:min-h-[77vh] items-center justify-center px-6">
          <div className="relative w-full max-w-5xl">
            <div
              key={currentTile.id}
              className="flex items-center justify-center transition-opacity duration-1000 opacity-100"
            >
              <TileBody tile={currentTile} />
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}

function TileBody({ tile }: { tile: HeroForegroundTile }) {
  if (tile.tile_type === "headline_cta") {
    return <HeadlineCtaTile payload={tile.payload as HeadlineCtaPayload} />;
  }
  return (
    <SponsorSpotlightTile payload={tile.payload as SponsorSpotlightPayload} />
  );
}

function HeadlineCtaTile({ payload }: { payload: HeadlineCtaPayload }) {
  return (
    <div className="text-center">
      <h1 className="font-black text-white text-5xl md:text-7xl uppercase tracking-tight">
        {payload.headline}
      </h1>
      <p className="text-white/90 text-lg md:text-xl mt-4 max-w-2xl mx-auto">
        {payload.subhead}
      </p>
      <div className="mt-8 flex justify-center">
        <Button
          size="lg"
          nativeButton={false}
          className="bg-mavs-navy text-white hover:bg-mavs-navy/90 px-8 py-3 font-bold uppercase h-auto"
          render={<Link href={payload.cta_url} />}
        >
          {payload.cta_label}
        </Button>
      </div>
    </div>
  );
}

function SponsorSpotlightTile({
  payload,
}: {
  payload: SponsorSpotlightPayload;
}) {
  const hasTagline =
    typeof payload.tagline === "string" && payload.tagline.length > 0;
  const bucket = payload.logo_bucket ?? "site-images";
  const logoSrc = publicStorageUrl(payload.logo_storage_path, bucket);
  const websiteUrl =
    typeof payload.website_url === "string" && payload.website_url.length > 0
      ? payload.website_url
      : null;
  /* eslint-disable @next/next/no-img-element */
  // Plain <img> on purpose: sponsor logos are arbitrary sizes from a public
  // bucket; next/image's intrinsic-sizing helps less than letting the natural
  // ratio render.
  const logo = (
    <img
      src={logoSrc}
      alt={payload.sponsor_name}
      className="h-24 md:h-32 mt-4 mx-auto"
    />
  );
  /* eslint-enable @next/next/no-img-element */
  return (
    <div className="text-white text-center">
      <p className="uppercase tracking-wide text-sm font-bold opacity-80">
        Thanks to our sponsor
      </p>
      {websiteUrl ? (
        <a
          href={websiteUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block hover:opacity-80 transition-opacity"
        >
          {logo}
        </a>
      ) : (
        logo
      )}
      <p className="mt-4 text-lg font-bold">{payload.sponsor_name}</p>
      {hasTagline ? (
        <p className="text-white/80 italic mt-1">{payload.tagline}</p>
      ) : null}
    </div>
  );
}

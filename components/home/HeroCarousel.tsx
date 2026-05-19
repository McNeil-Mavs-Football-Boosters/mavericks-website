"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

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

const BG_INTERVAL_MS = 7000;
const FG_INTERVAL_MS = 11000;

export function HeroCarousel({ backgrounds, tiles }: HeroCarouselProps) {
  const [bgIndex, setBgIndex] = useState(0);
  const [tileIndex, setTileIndex] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
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

  const shouldAnimate = !reducedMotion && !isHovered && !isHidden;

  // Background rotation.
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

  // Foreground rotation.
  useEffect(() => {
    if (!shouldAnimate) return;
    if (tiles.length <= 1) return;
    const id = window.setInterval(() => {
      setTileIndex((i) => (i + 1) % tiles.length);
    }, FG_INTERVAL_MS);
    return () => {
      window.clearInterval(id);
    };
  }, [shouldAnimate, tiles.length]);

  const hasBackgrounds = backgrounds.length > 0;
  const hasTiles = tiles.length > 0;
  const showScrim = hasBackgrounds && hasTiles;

  return (
    <section
      className={`relative isolate w-full min-h-[50vh] md:min-h-[70vh] overflow-hidden ${
        hasBackgrounds ? "" : "bg-mavs-navy"
      }`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
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
                className="object-cover"
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

      {hasTiles ? (
        <div className="relative z-10 flex min-h-[50vh] md:min-h-[70vh] items-center justify-center px-6">
          <div className="relative w-full max-w-5xl">
            {tiles.map((tile, idx) => (
              <div
                key={tile.id}
                className={`${
                  idx === 0 ? "relative" : "absolute inset-0"
                } flex items-center justify-center transition-opacity duration-1000 ${
                  idx === tileIndex ? "opacity-100" : "opacity-0"
                }`}
                aria-hidden={idx === tileIndex ? undefined : true}
              >
                <TileBody tile={tile} />
              </div>
            ))}
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
  return (
    <div className="text-white text-center">
      <p className="uppercase tracking-wide text-sm font-bold opacity-80">
        Thanks to our sponsor
      </p>
      {/* Plain <img> on purpose: sponsor logos are arbitrary sizes from a public bucket;
          next/image's intrinsic-sizing helps less here than letting the natural ratio render. */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={publicStorageUrl(payload.logo_storage_path)}
        alt={payload.sponsor_name}
        className="h-24 md:h-32 mt-4 mx-auto"
      />
      <p className="mt-4 text-lg font-bold">{payload.sponsor_name}</p>
      {hasTagline ? (
        <p className="text-white/80 italic mt-1">{payload.tagline}</p>
      ) : null}
    </div>
  );
}

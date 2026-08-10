"use client";

import { useEffect, useMemo, useState, useSyncExternalStore } from "react";

import {
  SponsorStripLogo,
  type SponsorStripLogoSponsor,
} from "@/components/sponsors/SponsorStripLogo";

const VISIBLE = 6;
const INTERVAL_MS = 4000;

/**
 * prefers-reduced-motion as an external store.
 *
 * Written this way on purpose: the equivalent in HeroCarousel calls setState
 * synchronously inside an effect, which trips react-hooks/set-state-in-effect
 * and costs an extra render at mount. useSyncExternalStore is the fix that was
 * already identified for that component but never applied. Server snapshot is
 * false so SSR renders the animated (default) markup.
 */
function useReducedMotion(): boolean {
  return useSyncExternalStore(
    (onChange) => {
      const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
      mql.addEventListener("change", onChange);
      return () => mql.removeEventListener("change", onChange);
    },
    () => window.matchMedia("(prefers-reduced-motion: reduce)").matches,
    () => false,
  );
}

/**
 * Homepage sponsor strip: one row, six logos, all the same size.
 *
 * Rotation is a SLIDING WINDOW, not paging. Every tick one logo leaves and one
 * arrives; paging by six would swap the whole row at once and read as a flash.
 *
 * ── Every sponsor is treated equally ──
 * There is no pinned slot. An earlier version held sponsors[0] in slot 1
 * permanently so the largest commitment could never rotate off screen, but
 * Jeremy asked 2026-08-09 for Rudy's to be "the same as everyone else on the
 * homepage". The window now walks the full list, so each sponsor gets the same
 * share of screen time and display order is purely sort_order.
 *
 * ── Behaviour matched to HeroCarousel ──
 * Pauses when the tab is hidden and respects prefers-reduced-motion (rendering
 * a static first window). Deliberately NO pause-on-hover: that caused a freeze
 * bug in HeroCarousel (commit 5934640) when the cursor happened to rest over the
 * element after a page load.
 *
 * ── Every logo stays in the DOM ──
 * Off-window logos are hidden with CSS, not unmounted, so crawlers and non-JS
 * visitors still see every sponsor. Sponsors are paying for visibility; they
 * should not be invisible to a search engine because of a rotation.
 */
export function SponsorCarousel({
  sponsors,
}: {
  sponsors: SponsorStripLogoSponsor[];
}) {
  const rotates = sponsors.length > VISIBLE;
  const [offset, setOffset] = useState(0);
  const reducedMotion = useReducedMotion();

  const animate = rotates && !reducedMotion;

  useEffect(() => {
    if (!animate || sponsors.length === 0) return;
    let id: ReturnType<typeof setInterval> | null = null;
    const start = () => {
      if (id === null) {
        id = setInterval(
          () => setOffset((o) => (o + 1) % sponsors.length),
          INTERVAL_MS,
        );
      }
    };
    const stop = () => {
      if (id !== null) {
        clearInterval(id);
        id = null;
      }
    };
    const onVisibility = () => (document.hidden ? stop() : start());
    if (!document.hidden) start();
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      stop();
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [animate, sponsors.length]);

  // The window is simply the first VISIBLE entries of the rotated order, so
  // there is no separate visibility set to keep in sync.
  const ordered = useMemo(() => {
    if (!rotates) return sponsors;
    return sponsors.map((_, i) => sponsors[(offset + i) % sponsors.length]!);
  }, [rotates, sponsors, offset]);

  return (
    <div
      className="flex flex-wrap items-center justify-center gap-8 md:gap-12"
      aria-label="Our sponsors"
    >
      {ordered.map((s, i) => {
        const shown = !rotates || i < VISIBLE;
        return (
          <div
            key={s.id}
            // Hidden entries keep their markup for crawlers but must not take
            // layout space or be tabbable, or the row would still be eight wide.
            className={
              shown
                ? "max-w-[200px] max-h-16 flex items-center justify-center transition-opacity duration-700 opacity-100"
                : "hidden"
            }
            aria-hidden={shown ? undefined : true}
          >
            <SponsorStripLogo sponsor={s} sizeClass="max-w-[200px] max-h-16" />
          </div>
        );
      })}
    </div>
  );
}
